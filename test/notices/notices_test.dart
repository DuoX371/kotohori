import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart';
import 'package:kotohori/features/notices/notices.dart';
import 'package:kotohori/features/update/update_check.dart';
import 'package:kotohori/platform/anki_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

const jitendex = Dictionary(
  id: 1,
  title: 'Jitendex',
  revision: '1',
  format: 3,
  isUpdatable: false,
  stylesCss: '',
  enabled: true,
  priority: 0,
);

void main() {
  Future<ProviderContainer> container({
    List<Dictionary> dicts = const [],
    AnkiStatus anki = const AnkiStatus(installed: true, permission: false),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        installedProvider.overrideWithValue(AsyncData(dicts)),
        ankiStatusProvider.overrideWithValue(AsyncData(anki)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  List<NoticeKind> kinds(ProviderContainer c) => [
    for (final n in c.read(noticesProvider)) n.kind,
  ];

  test('new install: dictionary and AnkiDroid permission', () async {
    final c = await container();
    expect(kinds(c), [NoticeKind.dictionary, NoticeKind.ankiPermission]);
  });

  test('permission granted but nothing chosen: set up', () async {
    final c = await container(
      dicts: [jitendex],
      anki: const AnkiStatus(installed: true, permission: true),
    );
    expect(kinds(c), [NoticeKind.ankiSetup]);
  });

  test('no AnkiDroid: suggest it, dismissible', () async {
    final c = await container(
      dicts: [jitendex],
      anki: const AnkiStatus(installed: false, permission: false),
    );
    expect(kinds(c), [NoticeKind.ankiMissing]);
    await c.read(dismissedNoticesProvider.notifier).dismiss('ankiMissing');
    expect(kinds(c), isEmpty);
  });

  test('update shows until "Later" for that version', () async {
    final c = await container(
      dicts: [jitendex],
      anki: const AnkiStatus(installed: false, permission: false),
    );
    await c.read(dismissedNoticesProvider.notifier).dismiss('ankiMissing');
    c.read(availableUpdateProvider.notifier).set((version: '0.2.0', url: 'u'));
    expect(kinds(c), [NoticeKind.update]);
    await c.read(dismissedNoticesProvider.notifier).dismiss('update:0.2.0');
    expect(kinds(c), isEmpty);
  });
}
