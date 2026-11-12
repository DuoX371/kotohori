import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/anki_bridge.dart';
import '../anki/anki_providers.dart';
import '../anki/anki_settings.dart';
import '../dictionary/ui/providers.dart' show installedProvider, prefsProvider;
import '../update/update_check.dart';

/// Things that need the user's attention, shown under the bell on the home
/// and Dictionary screens. Each one disappears once it's done (or dismissed).
enum NoticeKind { update, dictionary, ankiMissing, ankiPermission, ankiSetup }

typedef Notice = ({
  NoticeKind kind,
  IconData icon,
  String title,
  String body,
  String action,

  /// Dismiss key (null: can't be dismissed, it goes away when done).
  String? dismissKey,
});

/// AnkiDroid installed / permission. Re-read with `ref.invalidate` (app resume,
/// after asking for permission).
final ankiStatusProvider = FutureProvider<AnkiStatus>(
  (ref) => ref.watch(ankiBridgeProvider).status(),
);

/// Notices the user closed ("Later", "Dismiss"), saved.
class DismissedNotices extends Notifier<Set<String>> {
  static const _key = 'notices.dismissed';

  @override
  Set<String> build() =>
      (ref.watch(prefsProvider).getStringList(_key) ?? const []).toSet();

  Future<void> dismiss(String key) async {
    state = {...state, key};
    await ref.read(prefsProvider).setStringList(_key, state.toList());
  }
}

final dismissedNoticesProvider =
    NotifierProvider<DismissedNotices, Set<String>>(DismissedNotices.new);

final noticesProvider = Provider<List<Notice>>((ref) {
  final dismissed = ref.watch(dismissedNoticesProvider);
  final update = ref.watch(availableUpdateProvider);
  final dicts = ref.watch(installedProvider).value;
  final anki = ref.watch(ankiStatusProvider).value;
  return [
    if (update != null && !dismissed.contains('update:${update.version}'))
      (
        kind: NoticeKind.update,
        icon: Icons.system_update_outlined,
        title: 'Kotohori ${update.version} is available',
        body: 'Download the new version from its release page.',
        action: 'Download',
        dismissKey: 'update:${update.version}',
      ),
    if (dicts != null && dicts.isEmpty)
      (
        kind: NoticeKind.dictionary,
        icon: Icons.menu_book_outlined,
        title: 'Install a dictionary',
        body: 'You need one to look up words in subtitles.',
        action: 'Browse',
        dismissKey: null,
      ),
    if (anki != null && !anki.installed && !dismissed.contains('ankiMissing'))
      (
        kind: NoticeKind.ankiMissing,
        icon: Icons.style_outlined,
        title: 'Install AnkiDroid to make flashcards',
        body: 'Kotohori sends the words you mine to AnkiDroid.',
        action: 'Get AnkiDroid',
        dismissKey: 'ankiMissing',
      )
    else if (anki != null && anki.installed && !anki.permission)
      (
        kind: NoticeKind.ankiPermission,
        icon: Icons.style_outlined,
        title: 'Connect AnkiDroid',
        body: 'Allow Kotohori to add cards to AnkiDroid.',
        action: 'Allow',
        dismissKey: null,
      )
    else if (anki != null &&
        anki.permission &&
        !ref.watch(ankiSettingsProvider).isConfigured)
      (
        kind: NoticeKind.ankiSetup,
        icon: Icons.style_outlined,
        title: 'Choose a deck and card design',
        body: 'Pick where new cards go and how they look.',
        action: 'Set up',
        dismissKey: null,
      ),
  ];
});
