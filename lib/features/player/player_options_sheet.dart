import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/player_settings.dart';
import '../settings/subtitle_style_screen.dart';

import 'cue_list.dart';
import 'player_controller.dart';

String formatOffset(Duration d) {
  final ms = d.inMilliseconds;
  return '${ms >= 0 ? '+' : ''}${(ms / 1000).toStringAsFixed(1)}s';
}

/// [context] must outlive the sheet (the player screen): the sync picker
/// opens from it after this sheet closes.
/// [onAutoSync] is null when the video has no subtitles inside to match against.
Future<void> showPlayerOptions(
  BuildContext context,
  PlayerController c, {
  VoidCallback? onAutoSync,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: _PlayerOptions(
      c,
      onSync: () {
        Navigator.pop(sheetContext);
        showSyncPicker(context, c);
      },
      onAutoSync: onAutoSync == null
          ? null
          : () {
              Navigator.pop(sheetContext);
              onAutoSync();
            },
    ),
  ),
);

/// Full list of lines; picking one makes it start at the current position.
Future<void> showSyncPicker(BuildContext context, PlayerController c) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tap the line being spoken right now. It will start here.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: CueList(
                c,
                onPick: (cue) {
                  c.syncCueToNow(cue);
                  Navigator.pop(sheetContext);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Synced · offset ${formatOffset(c.timeline.offset)}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PlayerOptions extends StatelessWidget {
  const _PlayerOptions(
    this.c, {
    required this.onSync,
    required this.onAutoSync,
  });
  final PlayerController c;
  final VoidCallback onSync;
  final VoidCallback? onAutoSync;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.subtitles_outlined),
              title: const Text('Subtitles'),
              value: c.subtitlesOn,
              onChanged: (_) => c.toggleSubtitles(),
            ),
            ListTile(
              leading: const Icon(Icons.closed_caption_outlined),
              title: const Text('Subtitle appearance'),
              subtitle: const Text('Size, colour, outline or box'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SubtitleStyleScreen(),
                ),
              ),
            ),
            Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.play_circle_outline),
                    title: const Text('Autoplay'),
                    subtitle: const Text('Applies next time a video opens'),
                    value: ref.watch(autoplayProvider),
                    onChanged: ref.read(autoplayProvider.notifier).set,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.pause_circle_outline),
                    title: const Text('Pause on lookup'),
                    subtitle: const Text(
                      'Tapping a word pauses the video until you close the popup',
                    ),
                    value: ref.watch(pauseOnLookupProvider),
                    onChanged: ref.read(pauseOnLookupProvider.notifier).set,
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Subtitle timing', style: t.titleSmall),
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_outlined),
              title: const Text('Sync automatically'),
              subtitle: Text(
                onAutoSync == null
                    ? 'Needs an MKV video with subtitles inside it to match against'
                    : 'Match the timing to the subtitles inside the video',
              ),
              enabled: onAutoSync != null && c.timeline.cues.isNotEmpty,
              onTap: onAutoSync,
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync to a subtitle line'),
              subtitle: const Text(
                'Pause when someone starts speaking, then pick their line',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: c.timeline.cues.isNotEmpty,
              onTap: onSync,
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Offset'),
              subtitle: const Text('Positive = subtitles later'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Subtitles earlier',
                    icon: const Icon(Icons.remove),
                    onPressed: () =>
                        c.shiftOffset(-PlayerController.offsetStep),
                  ),
                  Text(
                    formatOffset(c.timeline.offset),
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Subtitles later',
                    icon: const Icon(Icons.add),
                    onPressed: () => c.shiftOffset(PlayerController.offsetStep),
                  ),
                  TextButton(
                    onPressed: c.timeline.offset == Duration.zero
                        ? null
                        : c.resetOffset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
