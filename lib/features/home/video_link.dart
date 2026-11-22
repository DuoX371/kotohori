import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// Streamed videos: a pasted http(s) link instead of a picked file.
bool isVideoLink(String uri) =>
    uri.startsWith('http://') || uri.startsWith('https://');

/// The link in [text] (trimmed), or null if it isn't an http(s) link.
/// A Google Drive share link becomes the file's direct download link.
Uri? parseVideoLink(String text) {
  final t = text.trim();
  final drive = RegExp(
    r'^https?://drive\.google\.com/(?:file/d/|open\?(?:.*&)?id=|uc\?(?:.*&)?id=)([\w-]{10,})',
  ).firstMatch(t);
  if (drive != null) {
    // confirm=t: skips Drive's "can't scan for viruses" page on big files.
    return Uri.https('drive.usercontent.google.com', '/download', {
      'id': drive[1]!,
      'export': 'download',
      'confirm': 't',
    });
  }
  final u = Uri.tryParse(t);
  return u != null &&
          (u.scheme == 'http' || u.scheme == 'https') &&
          u.host.isNotEmpty
      ? u
      : null;
}

/// A name for the link, used like a file name: its last path part, or the
/// folder above a playlist's generic "index.m3u8", or else the host.
String videoLinkName(Uri link) {
  final parts = link.pathSegments.where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return link.host;
  final last = parts.last;
  final playlist = RegExp(
    r'\.(m3u8|mpd)$',
    caseSensitive: false,
  ).hasMatch(last);
  if (!playlist) return last;
  return parts.length > 1 ? parts[parts.length - 2] : link.host;
}

/// The video's name if [link] is a video (the server's file name when it
/// sends one, as Drive does), or null if it isn't. Reads only the first
/// bytes, so a whole episode isn't downloaded.
Future<String?> checkVideoLink(Dio dio, Uri link) async {
  try {
    return await () async {
      final res = await dio.getUri<ResponseBody>(
        link,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Range': 'bytes=0-1023'},
          validateStatus: (_) => true,
        ),
      );
      final head = <int>[];
      // Leaving the loop closes the connection, even if the server ignored Range.
      await for (final chunk in res.data!.stream) {
        head.addAll(chunk);
        if (head.length >= 64) break;
      }
      if (!looksLikeVideo(
        res.statusCode ?? 0,
        res.headers.value(Headers.contentTypeHeader),
        head,
      )) {
        return null;
      }
      return fileNameFrom(res.headers.value('content-disposition')) ??
          videoLinkName(link);
    }().timeout(const Duration(seconds: 15));
  } on DioException {
    return null;
  } on TimeoutException {
    return null;
  }
}

/// Whether an answer (status, type, first bytes) can be a video. Only a web
/// page or an error is refused; unknown types are left to the player.
bool looksLikeVideo(int status, String? contentType, List<int> head) {
  if (status < 200 || status >= 400) return false;
  final start = utf8
      .decode(head.take(64).toList(), allowMalformed: true)
      .trimLeft()
      .toLowerCase();
  return !(contentType ?? '').toLowerCase().contains('html') &&
      !start.startsWith('<!doctype') &&
      !start.startsWith('<html');
}

/// The file name in a Content-Disposition header, if any.
String? fileNameFrom(String? disposition) {
  if (disposition == null) return null;
  final star = RegExp(r"filename\*=(?:UTF-8|utf-8)''([^;]+)")
      .firstMatch(disposition);
  if (star != null) return Uri.decodeComponent(star[1]!.trim());
  final plain = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
  final name = plain?[1]?.trim();
  return name == null || name.isEmpty ? null : name;
}
