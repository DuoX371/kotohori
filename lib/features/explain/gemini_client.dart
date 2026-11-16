import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// A Gemini model the user can pick for Explain.
class GeminiModel {
  const GeminiModel(this.id, this.label, this.summary);

  /// The API's name for it.
  final String id;
  final String label;

  /// One line for the settings page: what it's like and its free allowance.
  final String summary;
}

/// The choices, default first. All are stable and on Gemini's free tier. On
/// 2026-11-16 the free plan allowed about 500 requests a day on the Flash-Lite
/// models and about 20 on the Flash ones; Google changes these, so the
/// summaries only say "high" and "low".
/// Tried with the real prompt that day: the Flash models got the grammar right
/// in about 2 s; Flash-Lite was a little faster but sometimes listed a word
/// that wasn't in the line.
const geminiModels = [
  GeminiModel(
    'gemini-3.5-flash-lite',
    'Gemini 3.5 Flash-Lite',
    'Fast · high free limit',
  ),
  GeminiModel(
    'gemini-3.1-flash-lite',
    'Gemini 3.1 Flash-Lite',
    'Older · high free limit',
  ),
  GeminiModel(
    'gemini-3.6-flash',
    'Gemini 3.6 Flash',
    'More accurate · low free limit',
  ),
  GeminiModel(
    'gemini-3.8-flash',
    'Gemini 3.8 Flash',
    'Most accurate · low free limit · often busy',
  ),
];

/// The model for [id]; the default when [id] is unknown (a retired choice).
GeminiModel geminiModelFor(String? id) => geminiModels.firstWhere(
  (m) => m.id == id,
  orElse: () => geminiModels.first,
);

enum ExplainError { unreachable, badKey, limit, noModel, busy, other }

class ExplainException implements Exception {
  const ExplainException(this.kind, [this.detail]);
  final ExplainError kind;

  /// The server's own words, when it sent any.
  final String? detail;

  @override
  String toString() => 'ExplainException(${kind.name}, $detail)';
}

/// Talks to the Gemini API with the user's own key.
class GeminiClient {
  GeminiClient(this._dio, {required String apiKey, required this.model})
    : _key = apiKey.trim();

  final Dio _dio;
  final String _key;
  final String model;

  static const _host = 'https://generativelanguage.googleapis.com';
  static const _connect = Duration(seconds: 15);
  static const _silence = Duration(seconds: 30);

  /// The answer to [user] (under the standing [system] instructions) as it is
  /// written, piece by piece. Cancel the subscription to stop the request.
  /// Fails with [ExplainException].
  Stream<String> ask({required String system, required String user}) {
    final cancel = CancelToken();
    late final StreamController<String> out;
    Future<void> run() async {
      try {
        // A short answer needs little reasoning, and thinking delays the first
        // words. If the model rejects the option, ask again without it.
        var (status, lines) = await _post(system, user, cancel, think: 'LOW');
        if (status == 400) {
          final body = await lines.join('\n');
          if (!body.toLowerCase().contains('thinking')) _fail(status, body);
          (status, lines) = await _post(system, user, cancel);
        }
        if (status != null && status >= 400) {
          _fail(status, await lines.join('\n'));
        }
        // Server-sent events: each "data:" line is one JSON chunk.
        await for (final line in lines) {
          if (!line.startsWith('data:')) continue;
          final Object? j;
          try {
            j = jsonDecode(line.substring(5));
          } on FormatException {
            continue; // a cut-off last line
          }
          if (j is! Map) continue;
          if (j['error'] != null) _fail(null, jsonEncode(j));
          final text = _text(j);
          if (text.isNotEmpty && !out.isClosed) out.add(text);
          final blocked = _blocked(j);
          if (blocked != null) {
            throw ExplainException(ExplainError.other, blocked);
          }
        }
      } on ExplainException catch (e) {
        if (!out.isClosed) out.addError(e);
      } on Object catch (e) {
        if (!out.isClosed && !cancel.isCancelled) out.addError(_network(e));
      } finally {
        if (!out.isClosed) await out.close();
      }
    }

    out = StreamController<String>(
      onListen: run,
      onCancel: () => cancel.cancel(),
    );
    return out.stream;
  }

  /// Checks the key and that the model is on offer by reading the model's
  /// details: no question is asked, so it doesn't count against the daily
  /// allowance. Fails with [ExplainException].
  Future<void> checkKey() async {
    final Response<String> r;
    try {
      r = await _dio
          .get<String>(
            '$_host/v1beta/models/$model',
            options: Options(
              responseType: ResponseType.plain,
              headers: {'x-goog-api-key': _key},
              receiveTimeout: _connect,
              validateStatus: (_) => true,
            ),
          )
          .timeout(_connect);
    } on Object catch (e) {
      throw _network(e);
    }
    final status = r.statusCode;
    if (status == null || status >= 400) _fail(status, r.data ?? '');
  }

  /// The visible text of one chunk (the model's private thoughts are skipped).
  static String _text(Map<Object?, Object?> chunk) {
    final candidates = chunk['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final first = candidates.first;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) return '';
    return [
      for (final p in parts)
        if (p is Map && p['thought'] != true && p['text'] is String) p['text'],
    ].join();
  }

  /// Why Gemini refused or cut the answer, or null if it didn't.
  static String? _blocked(Map<Object?, Object?> chunk) {
    final feedback = chunk['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) {
      return 'Gemini declined to explain this line.';
    }
    final candidates = chunk['candidates'];
    final first = candidates is List && candidates.isNotEmpty
        ? candidates.first
        : null;
    final reason = first is Map ? first['finishReason'] : null;
    return switch (reason) {
      null || 'STOP' || 'FINISH_REASON_UNSPECIFIED' => null,
      'MAX_TOKENS' => 'The answer was too long and was cut off.',
      _ => 'Gemini declined to explain this line.',
    };
  }

  /// A failure that isn't Google's answer: no connection, a timeout, or a bug
  /// of ours (reported as such, not blamed on the network).
  static ExplainException _network(Object e) {
    if (e is TimeoutException) return const ExplainException(ExplainError.busy);
    if (e is DioException) {
      // Never e.toString(): it can carry request details.
      return ExplainException(
        ExplainError.unreachable,
        '${e.type.name}${e.error == null ? '' : ': ${e.error}'}',
      );
    }
    return ExplainException(ExplainError.other, 'Unexpected error: $e');
  }

  /// Status code and the body as lines.
  Future<(int?, Stream<String>)> _post(
    String system,
    String user,
    CancelToken cancel, {
    String? think,
  }) async {
    final r = await _dio
        .post<ResponseBody>(
          '$_host/v1beta/models/$model:streamGenerateContent?alt=sse',
          data: {
            'systemInstruction': {
              'parts': [
                {'text': system},
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': user},
                ],
              },
            ],
            if (think != null)
              'generationConfig': {
                'thinkingConfig': {'thinkingLevel': think},
              },
          },
          options: Options(
            responseType: ResponseType.stream,
            headers: {'x-goog-api-key': _key},
            sendTimeout: _connect,
            receiveTimeout: _silence,
            validateStatus: (_) => true, // read the error body ourselves
          ),
          cancelToken: cancel,
        )
        .timeout(_silence);
    return (
      r.statusCode,
      r.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(_silence),
    );
  }

  /// Throws what [body] (Google's `{"error": {...}}`) means.
  Never _fail(int? httpStatus, String body) {
    String? message, status;
    int? code = httpStatus;
    try {
      final j = jsonDecode(body);
      final e = j is Map ? j['error'] : null;
      if (e is Map) {
        message = e['message'] as String?;
        status = e['status'] as String?;
        code ??= e['code'] as int?;
      }
    } on Object {
      // not JSON: an HTML error page or similar
    }
    final low = (message ?? '').toLowerCase();
    throw ExplainException(switch ((code, status)) {
      _ when low.contains('api key') => ExplainError.badKey,
      (401 || 403, _) || (_, 'PERMISSION_DENIED') => ExplainError.badKey,
      (429, _) || (_, 'RESOURCE_EXHAUSTED') => ExplainError.limit,
      (404, _) || (_, 'NOT_FOUND') => ExplainError.noModel,
      (500 || 503, _) || (_, 'UNAVAILABLE') => ExplainError.busy,
      _ => ExplainError.other,
    }, message ?? (code == null ? null : 'HTTP $code'));
  }
}
