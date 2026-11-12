import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart'
    show prefsProvider;
import 'package:kotohori/features/home/last_session.dart';
import 'package:kotohori/features/subtitles/auto_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> container([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: [prefsProvider.overrideWithValue(p)]);
  }

  test('saves, updates subtitle sync, survives a restart', () async {
    var c = await container();
    expect(c.read(lastSessionProvider), isNull);
    final n = c.read(lastSessionProvider.notifier);
    await n.save(
      const LastSession(
        videoUri: 'content://v',
        videoName: 'ep1.mkv',
        subsUri: 'content://s',
        subsName: 'ep1.ass',
      ),
    );
    await n.saveResumePoint((
      position: const Duration(minutes: 3, seconds: 7),
      offset: const Duration(milliseconds: -1200),
      subtitlesOn: false,
      sync: const [
        SyncSegment(Duration.zero, Duration(seconds: -32)),
        SyncSegment(Duration(minutes: 5), Duration(seconds: -42)),
      ],
    ));

    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    final s = c.read(lastSessionProvider)!;
    expect(
      (
        s.videoUri,
        s.videoName,
        s.subsUri,
        s.subsName,
        s.position,
        s.offset,
        s.subtitlesOn,
      ),
      (
        'content://v',
        'ep1.mkv',
        'content://s',
        'ep1.ass',
        const Duration(minutes: 3, seconds: 7),
        const Duration(milliseconds: -1200),
        false,
      ),
    );
    // Lists inside records compare by identity, so check the sync separately.
    expect(s.sync, const [
      SyncSegment(Duration.zero, Duration(seconds: -32)),
      SyncSegment(Duration(minutes: 5), Duration(seconds: -42)),
    ]);
  });

  test('corrupt or incomplete data → no session', () async {
    expect(
      (await container({'session.last': '{not json'}))
          .read(lastSessionProvider),
      isNull,
    );
    expect(
      (await container({'session.last': '{"videoName":"x"}'}))
          .read(lastSessionProvider),
      isNull,
    );
  });
}
