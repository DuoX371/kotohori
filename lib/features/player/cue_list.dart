import 'dart:async';

import 'package:flutter/material.dart';

import '../subtitles/cue.dart';
import 'player_controller.dart';
import 'player_options_sheet.dart';

/// Scrollable cue list; follows the current cue. Tap jumps to the line, or,
/// with [onPick], selects it (sync mode: each row shows the shift it would apply).
class CueList extends StatefulWidget {
  const CueList(this.c, {super.key, this.onPick});
  final PlayerController c;
  final ValueChanged<Cue>? onPick;

  @override
  State<CueList> createState() => _CueListState();
}

class _CueListState extends State<CueList> {
  // shortcut: builds every row eagerly so ensureVisible can reach any cue;
  // fine for episode-length files (hundreds of cues), switch to an indexed list if films lag.
  final _keys = <int, GlobalKey>{};
  int? _current;
  StreamSubscription<bool>? _playing;

  @override
  void initState() {
    super.initState();
    widget.c.addListener(_follow);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _follow(animate: false),
    );
    // Sync mode: refresh the shift hints when the user pauses/plays, so they
    // match the exact paused position (the list otherwise rebuilds per line).
    if (widget.onPick != null) {
      _playing = widget.c.player.stream.playing.listen((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    widget.c.removeListener(_follow);
    _playing?.cancel();
    super.dispose();
  }

  void _follow({bool animate = true}) {
    final cur = widget.c.timeline.currentAt(widget.c.position)?.index;
    if (cur == _current) return;
    setState(() => _current = cur);
    final ctx = cur == null ? null : _keys[cur]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cues = widget.c.timeline.cues;
    if (cues.isEmpty) return const Center(child: Text('No subtitles loaded'));
    final scheme = Theme.of(context).colorScheme;
    final t = widget.c.timeline;
    final pick = widget.onPick;
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final cue in cues)
            ListTile(
              key: _keys[cue.index] ??= GlobalKey(),
              dense: true,
              selected: cue.index == _current,
              selectedTileColor: scheme.primaryContainer,
              leading: Text(
                _fmt(t.startOf(cue)),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              title: Text(cue.text),
              // How far the subtitles would move if this line started now.
              trailing: pick == null
                  ? null
                  : Text(
                      formatOffset(
                        t.offsetToStart(cue, widget.c.position) - t.offset,
                      ),
                    ),
              onTap: pick == null
                  ? () => widget.c.seekToCue(cue)
                  : () => pick(cue),
            ),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  final neg = d.isNegative ? '-' : '';
  d = d.abs();
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '$neg${d.inHours}:$m:$s' : '$neg$m:$s';
}

String formatDuration(Duration d) => _fmt(d);
