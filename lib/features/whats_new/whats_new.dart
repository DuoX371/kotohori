import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;
import '../update/update_check.dart';
import 'changelog.dart';

/// The changelog shipped inside the app (the same file as on GitHub).
const changelogAsset = 'docs/CHANGELOG.md';

final changelogProvider = FutureProvider<List<ChangelogRelease>>(
  (_) async => parseChangelog(await rootBundle.loadString(changelogAsset)),
);

/// The version whose "What's new" the user last saw. A fresh install starts at
/// the installed version (see `main`), so it has nothing to announce.
class WhatsNewSeen extends Notifier<String?> {
  static const key = 'whatsNew.seen';

  @override
  String? build() => ref.watch(prefsProvider).getString(key);

  Future<void> set(String version) async {
    await ref.read(prefsProvider).setString(key, version);
    state = version;
  }
}

final whatsNewSeenProvider = NotifierProvider<WhatsNewSeen, String?>(
  WhatsNewSeen.new,
);

/// Releases to announce now (empty: nothing new, or still loading).
final whatsNewProvider = Provider<List<ChangelogRelease>>((ref) {
  final all = ref.watch(changelogProvider).value;
  final installed = ref.watch(appVersionProvider).value;
  if (all == null || installed == null || installed == '?') return const [];
  return unseenReleases(
    all,
    installed: installed,
    seen: ref.watch(whatsNewSeenProvider),
  );
});
