import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart'
    show prefsProvider;
import 'package:kotohori/features/explain/explain_request.dart';
import 'package:kotohori/features/explain/explain_session.dart';
import 'package:kotohori/features/explain/explain_settings.dart';
import 'package:kotohori/features/explain/gemini_client.dart';
import 'package:kotohori/features/subtitles/cue.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryKeyStore implements KeyStore {
  var _key = '';

  @override
  Future<String> read() async => _key;

  @override
  Future<void> write(String key) async => _key = key;
}

/// Cues from (start, end) seconds; text is the index.
List<Cue> cuesAt(List<(int, int)> times) => [
  for (final (i, (s, e)) in times.indexed)
    Cue(i, Duration(seconds: s), Duration(seconds: e), 'line$i'),
];

/// Answers each request with the next canned (status, body chunks).
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.replies);
  final List<(int, List<String>)> replies;
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(options.data);
    final (status, chunks) = replies.removeAt(0);
    return ResponseBody(
      Stream.fromIterable([
        for (final c in chunks) Uint8List.fromList(utf8.encode(c)),
      ]),
      status,
    );
  }

  @override
  void close({bool force = false}) {}
}

GeminiClient clientWith(FakeAdapter a, {String key = 'k'}) =>
    GeminiClient(Dio()..httpClientAdapter = a, apiKey: key, model: 'the-model');

/// One server-sent event carrying [text] (optionally as a private thought).
String piece(String text, {bool thought = false, String? finish}) =>
    'data: ${jsonEncode({
      'candidates': [
        {
          'content': {
            'role': 'model',
            'parts': [
              {'text': text, 'thought': ?(thought ? true : null)},
            ],
          },
          'finishReason': ?finish,
        },
      ],
    })}\n\n';

String errorBody(int code, String status, String message) =>
    const JsonEncoder.withIndent('  ').convert({
      'error': {'code': code, 'message': message, 'status': status},
    });

ExplainRequest request(List<Cue> cues, int target, {String model = 'm'}) =>
    ExplainRequest(
      title: 'Show - 01',
      lines: explainContext(cues, [cues[target]]),
      targets: [cues[target]],
      model: model,
    );

void main() {
  group('explainContext', () {
    test('takes up to three lines each side', () {
      final cues = cuesAt([for (var i = 0; i < 10; i++) (i * 3, i * 3 + 2)]);
      final lines = explainContext(cues, [cues[5]]);
      expect(lines.map((c) => c.index), [2, 3, 4, 5, 6, 7, 8]);
    });

    test('never crosses a long silence, in either direction', () {
      // 0-2, 3-5 | 85-87, 88-90 (target), 91-93 | 180-182
      final cues = cuesAt([
        (0, 2),
        (3, 5),
        (85, 87),
        (88, 90),
        (91, 93),
        (180, 182),
      ]);
      expect(explainContext(cues, [cues[3]]).map((c) => c.index), [2, 3, 4]);
    });

    test('a silence stops the walk even if nearer lines follow it', () {
      // target, then a 60 s hole, then two lines close together
      final cues = cuesAt([(0, 2), (62, 64), (65, 67)]);
      expect(explainContext(cues, [cues[0]]).map((c) => c.index), [0]);
    });

    test('first and last lines of the file', () {
      final cues = cuesAt([(0, 2), (3, 5), (6, 8)]);
      expect(explainContext(cues, [cues[0]]).map((c) => c.index), [0, 1, 2]);
      expect(explainContext(cues, [cues[2]]).map((c) => c.index), [0, 1, 2]);
    });

    test('overlapping lines count as close; two targets stay together', () {
      final cues = cuesAt([(0, 5), (4, 9), (8, 12), (40, 42)]);
      final lines = explainContext(cues, [cues[1], cues[2]]);
      expect(lines.map((c) => c.index), [0, 1, 2]);
    });
  });

  test('show prompt is unchanged by book support', () {
    const c = Cue(0, Duration.zero, Duration(seconds: 1), '行');
    final p = explainPrompt(
      const ExplainRequest(title: 'T', lines: [c], targets: [c], model: 'm'),
    );
    expect(
      sha256.convert(utf8.encode(p.system)).toString(),
      'adffb4ad8755390004a71128d2d37d43e6ff092056282db8c8ff1c9873b4780d',
    );
    expect(p.user, 'Show: T\n\nSubtitle lines:\n> 行');
  });

  test('a paragraph gets the lighter prompt, every sentence marked', () {
    const a = Cue(0, Duration.zero, Duration.zero, '前。');
    const b = Cue(1, Duration.zero, Duration.zero, '一。');
    const c = Cue(2, Duration.zero, Duration.zero, '二。');
    final p = explainPrompt(
      const ExplainRequest(
        title: '本',
        lines: [a, b, c],
        targets: [b, c],
        model: 'm',
        source: ExplainSource.book,
        paragraph: true,
      ),
    );
    expect(p.system, contains('## Hard parts'));
    expect(p.system, isNot(contains('## Breakdown')));
    expect(p.user, 'Book: 本\n\nSentences:\n  前。\n> 一。\n> 二。');
  });

  test('book prompt talks about a novel and its sentences', () {
    const a = Cue(0, Duration.zero, Duration.zero, '前の文。');
    const b = Cue(1, Duration.zero, Duration.zero, '対象の文。');
    final p = explainPrompt(
      const ExplainRequest(
        title: '本のタイトル',
        lines: [a, b],
        targets: [b],
        model: 'm',
        source: ExplainSource.book,
      ),
    );
    expect(
      p.system,
      startsWith(
        'You help an English-speaking learner of Japanese who is reading a Japanese light novel.\n'
        'You are given a few sentences in order. Explain only the sentence or sentences marked with ">". '
        'The other sentences are there only so you understand the scene; do not explain them.\n',
      ),
    );
    expect(p.system, contains('## Translation'));
    expect(p.user, 'Book: 本のタイトル\n\nSentences:\n  前の文。\n> 対象の文。');
  });

  test('the prompt marks only the target and names the show', () {
    final cues = [
      const Cue(0, Duration.zero, Duration(seconds: 2), '前の行'),
      const Cue(1, Duration(seconds: 3), Duration(seconds: 5), '対象\nの行'),
      const Cue(2, Duration(seconds: 6), Duration(seconds: 8), '次の行'),
    ];
    final r = request(cues, 1);
    final prompt = explainPrompt(r);
    expect(prompt.system, contains('## Translation'));
    expect(prompt.user, contains('Show: Show - 01'));
    expect(prompt.user, contains('  前の行\n> 対象 の行\n  次の行'));
    expect(r.targetText, '対象 の行');
  });

  group('GeminiClient', () {
    Stream<String> ask(FakeAdapter a) =>
        clientWith(a).ask(system: 'sys', user: 'hi');

    test('streams the answer and sends the key and the prompt', () async {
      final a = FakeAdapter([
        (
          200,
          [
            piece('He'),
            // a chunk boundary in the middle of an event, and a thought to skip
            piece('llo').substring(0, 20),
            piece('llo').substring(20),
            piece('hmm', thought: true),
            piece('!', finish: 'STOP'),
          ],
        ),
      ]);
      expect(await ask(a).join(), 'Hello!');
      final sent = a.requests.single;
      expect(
        sent.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'the-model:streamGenerateContent?alt=sse',
      );
      expect(sent.headers['x-goog-api-key'], 'k');
      expect(sent.uri.toString(), isNot(contains('key=')));
      expect(a.bodies.single, {
        'systemInstruction': {
          'parts': [
            {'text': 'sys'},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': 'hi'},
            ],
          },
        ],
        'generationConfig': {
          'thinkingConfig': {'thinkingLevel': 'LOW'},
        },
      });
    });

    test(
      'a model that rejects the thinking option is asked without it',
      () async {
        final a = FakeAdapter([
          (
            400,
            [
              errorBody(
                400,
                'INVALID_ARGUMENT',
                'Thinking level is not supported for this model.',
              ),
            ],
          ),
          (200, [piece('ok')]),
        ]);
        expect(await ask(a).join(), 'ok');
        expect((a.bodies.last as Map).containsKey('generationConfig'), isFalse);
      },
    );

    Future<ExplainException> failure(int status, String body) async {
      try {
        await ask(
          FakeAdapter([
            (status, [body]),
          ]),
        ).join();
      } on ExplainException catch (e) {
        return e;
      }
      fail('no error');
    }

    test(
      'checking the key asks about the model without asking a question',
      () async {
        final ok = FakeAdapter([
          (200, ['{"name":"models/the-model"}']),
        ]);
        await clientWith(ok).checkKey();
        final sent = ok.requests.single;
        expect(sent.method, 'GET');
        expect(
          sent.uri.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/the-model',
        );
        expect(sent.headers['x-goog-api-key'], 'k');

        final bad = FakeAdapter([
          (
            400,
            [
              errorBody(
                400,
                'INVALID_ARGUMENT',
                'API key not valid. Please pass a valid API key.',
              ),
            ],
          ),
        ]);
        await expectLater(
          clientWith(bad).checkKey(),
          throwsA(
            isA<ExplainException>().having(
              (e) => e.kind,
              'kind',
              ExplainError.badKey,
            ),
          ),
        );
      },
    );

    test('errors map to plain kinds', () async {
      // Google answers a wrong key with 400, not 401.
      expect(
        (await failure(
          400,
          errorBody(
            400,
            'INVALID_ARGUMENT',
            'API key not valid. Please pass a valid API key.',
          ),
        )).kind,
        ExplainError.badKey,
      );
      expect(
        (await failure(403, errorBody(403, 'PERMISSION_DENIED', 'no'))).kind,
        ExplainError.badKey,
      );
      expect(
        (await failure(
          429,
          errorBody(429, 'RESOURCE_EXHAUSTED', 'Quota exceeded'),
        )).kind,
        ExplainError.limit,
      );
      expect(
        (await failure(404, errorBody(404, 'NOT_FOUND', 'gone'))).kind,
        ExplainError.noModel,
      );
      expect(
        (await failure(503, errorBody(503, 'UNAVAILABLE', 'overloaded'))).kind,
        ExplainError.busy,
      );
      final other = await failure(
        400,
        errorBody(400, 'INVALID_ARGUMENT', 'boom'),
      );
      expect(other.kind, ExplainError.other);
      expect(other.detail, 'boom');
      expect((await failure(502, '<html>bad</html>')).kind, ExplainError.other);
    });

    test('a refused or cut-off answer says so after the text', () async {
      final got = <String>[];
      Object? error;
      final done = Completer<void>();
      ask(
        FakeAdapter([
          (200, [piece('Half'), piece('', finish: 'SAFETY')]),
        ]),
      ).listen(
        got.add,
        onError: (Object e) => error = e,
        onDone: done.complete,
      );
      await done.future;
      expect(got, ['Half']);
      expect((error as ExplainException).kind, ExplainError.other);
    });

    test('an error in the middle of the stream fails after the text', () async {
      final got = <String>[];
      Object? error;
      final done = Completer<void>();
      ask(
        FakeAdapter([
          (
            200,
            [
              piece('Half'),
              'data: ${jsonEncode({
                'error': {'code': 429, 'message': 'Quota exceeded', 'status': 'RESOURCE_EXHAUSTED'},
              })}\n\n',
            ],
          ),
        ]),
      ).listen(
        got.add,
        onError: (Object e) => error = e,
        onDone: done.complete,
      );
      await done.future;
      expect(got, ['Half']);
      expect((error as ExplainException).kind, ExplainError.limit);
    });
  });

  group('ExplainSession', () {
    final cues = cuesAt([(0, 2), (3, 5), (6, 8)]);

    test('writes the answer as it arrives, then keeps it', () async {
      final answer = StreamController<String>();
      var asked = 0;
      final s = ExplainSession((_) {
        asked++;
        return answer.stream;
      });
      s.start(request(cues, 1));
      expect(s.isOpen, isTrue);
      expect(s.status, ExplainStatus.waiting);
      answer.add('## Trans');
      await pumpEventQueue();
      expect(s.status, ExplainStatus.writing);
      answer.add('lation');
      await answer.close();
      await pumpEventQueue();
      expect(s.status, ExplainStatus.done);
      expect(s.text, '## Translation');

      // Same line again: shown from memory, nothing asked.
      s.close();
      expect(s.isOpen, isFalse);
      s.start(request(cues, 1));
      expect(s.text, '## Translation');
      expect(s.status, ExplainStatus.done);
      expect(asked, 1);
    });

    test('asking again, another model or another line asks anew', () async {
      var asked = 0;
      final s = ExplainSession((r) {
        asked++;
        return Stream.value('answer $asked');
      });
      s.start(request(cues, 1));
      await pumpEventQueue();
      s.regenerate();
      await pumpEventQueue();
      expect(s.text, 'answer 2');
      s.start(request(cues, 2));
      await pumpEventQueue();
      s.start(request(cues, 1, model: 'other'));
      await pumpEventQueue();
      expect(asked, 4);
      s.start(request(cues, 1)); // the regenerated answer replaced the first
      expect(s.text, 'answer 2');
    });

    test('closing or a new line stops the answer in progress', () async {
      final cancelled = <int>[];
      var n = 0;
      final late = <StreamController<String>>[];
      final s = ExplainSession((_) {
        final id = n++;
        final c = StreamController<String>(onCancel: () => cancelled.add(id));
        late.add(c);
        return c.stream;
      });
      s.start(request(cues, 0));
      s.start(request(cues, 1));
      expect(cancelled, [0]);
      late[0].add('too late'); // must not leak into the new line
      await pumpEventQueue();
      expect(s.text, '');
      s.close();
      expect(cancelled, [0, 1]);
      expect(s.isOpen, isFalse);
    });

    test('a failure keeps what arrived and is not saved', () async {
      var asked = 0;
      final s = ExplainSession((_) async* {
        asked++;
        yield 'Half';
        throw const ExplainException(ExplainError.limit);
      });
      s.start(request(cues, 1));
      await pumpEventQueue();
      expect(s.status, ExplainStatus.failed);
      expect(s.error?.kind, ExplainError.limit);
      expect(s.text, 'Half');
      s.start(request(cues, 1));
      await pumpEventQueue();
      expect(asked, 2);
    });

    test('an empty answer counts as a failure', () async {
      final s = ExplainSession((_) => const Stream.empty());
      s.start(request(cues, 1));
      await pumpEventQueue();
      expect(s.status, ExplainStatus.failed);
    });
  });

  test('the default model is first; an unknown saved one falls back to it', () {
    expect(geminiModelFor(null).id, 'gemini-3.5-flash-lite');
    expect(geminiModelFor('retired-model').id, 'gemini-3.5-flash-lite');
    expect(geminiModelFor('gemini-3.8-flash').label, 'Gemini 3.8 Flash');
    expect({for (final m in geminiModels) m.id}.length, geminiModels.length);
  });

  test(
    'Explain only turns on after the key passes; a new key needs a new test',
    () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          keyStoreProvider.overrideWithValue(_MemoryKeyStore()),
        ],
      );
      addTearDown(c.dispose);
      final enabled = c.read(explainEnabledProvider.notifier);
      final key = c.read(explainApiKeyProvider.notifier);
      final tested = c.read(explainKeyTestedProvider.notifier);

      await key.set('first');
      await enabled.set(true);
      expect(c.read(explainEnabledProvider), isFalse, reason: 'not tested yet');

      await tested.passed('first');
      await enabled.set(true);
      expect(c.read(explainEnabledProvider), isTrue);

      await key.set(' first '); // the same key again changes nothing
      expect(c.read(explainEnabledProvider), isTrue);

      await key.set('second');
      expect(c.read(explainKeyTestedProvider), isFalse);
      expect(c.read(explainEnabledProvider), isFalse, reason: 'new key');

      await tested.passed('first'); // a test of the old key that finished late
      expect(c.read(explainKeyTestedProvider), isFalse);

      await tested.passed('second');
      expect(c.read(explainKeyTestedProvider), isTrue);
      expect(c.read(explainEnabledProvider), isTrue, reason: 'was on before');

      // A slip of the finger, then fixed: the key that passed still counts.
      await key.set('secon');
      expect(c.read(explainEnabledProvider), isFalse);
      await key.set('second');
      expect(c.read(explainKeyTestedProvider), isTrue);
      expect(c.read(explainEnabledProvider), isTrue);
    },
  );

  test('Explain needs a key', () {
    expect(explainSetupProblem(apiKey: ' '), contains('API key'));
    expect(explainSetupProblem(apiKey: 'k'), isNull);
  });
}
