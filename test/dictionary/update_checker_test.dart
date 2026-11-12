import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/update/update_checker.dart';

import '../helpers.dart';

/// Serves canned bodies by URL; anything else is a 404.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);
  final Map<String, String> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    final r = routes[o.uri.toString()];
    return r == null
        ? ResponseBody.fromString('not found', 404)
        : ResponseBody.fromString(
            r,
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late TestEnv env;
  setUp(() async {
    env = await TestEnv.create();
    await env.import('mini_a');
    await env.import('mini_b'); // not updatable
  });
  tearDown(() => env.dispose());

  Dio dio(Map<String, String> routes) =>
      Dio()..httpClientAdapter = FakeAdapter(routes);

  test('detects a newer revision from the mocked indexUrl', () async {
    final res = await checkForUpdates(
      dio({
        'https://example.test/mini_a/index.json': jsonEncode({
          'title': 'Mini A',
          'revision': '2025.02.01.0',
          'format': 3,
          'downloadUrl': 'https://example.test/mini_a_v2.zip',
        }),
      }),
      await env.repo.installed(),
    );
    expect(res.failures, isEmpty);
    final u = res.updates.single;
    expect(u.dictionary.title, 'Mini A');
    expect(u.latestRevision, '2025.02.01.0');
    expect(u.downloadUrl, 'https://example.test/mini_a_v2.zip');
  });

  test('same revision → no update; falls back to stored downloadUrl', () async {
    final res = await checkForUpdates(
      dio({
        'https://example.test/mini_a/index.json': jsonEncode({
          'revision': '2025.01.01.0',
        }),
      }),
      await env.repo.installed(),
    );
    expect(res.updates, isEmpty);
    expect(res.failures, isEmpty);
  });

  test('HTTP failure is reported per dictionary', () async {
    final res = await checkForUpdates(dio({}), await env.repo.installed());
    expect(res.updates, isEmpty);
    expect(res.failures.keys, ['Mini A']);
  });
}
