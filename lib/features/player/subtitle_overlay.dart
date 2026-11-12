import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/subtitle_style.dart';

import 'player_controller.dart';

/// Our own subtitle renderer: one text block per active cue, every character
/// tappable (tap → character index via the laid-out paragraph).
class SubtitleOverlay extends ConsumerWidget {
  const SubtitleOverlay(this.c, {super.key});
  final PlayerController c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(subtitleStyleProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.lookup]),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.subtitlesOn)
            for (final cue in c.active)
              SubtitleText(
                cue.text,
                style: style,
                highlight: switch (c.lookup.highlight) {
                  (final i, final start, final len) when i == cue.index => (
                    start,
                    len,
                  ),
                  _ => null,
                },
                onTapChar: (i) => c.tapCharacter(cue, i),
              ),
        ],
      ),
    );
  }
}

/// One subtitle line drawn with the user's [SubtitleStyle]; also used by the
/// style preview. [onTapChar] gets the index of the tapped character.
class SubtitleText extends StatefulWidget {
  const SubtitleText(
    this.text, {
    super.key,
    required this.style,
    this.highlight,
    this.onTapChar,
  });
  final String text;
  final SubtitleStyle style;
  final (int, int)? highlight;
  final ValueChanged<int>? onTapChar;

  @override
  State<SubtitleText> createState() => _SubtitleTextState();
}

class _SubtitleTextState extends State<SubtitleText> {
  final _key = GlobalKey();

  void _onTap(TapUpDetails d) {
    final rp = _key.currentContext?.findRenderObject();
    if (rp is! RenderParagraph) return;
    final local = rp.globalToLocal(d.globalPosition);
    final text = widget.text;
    final i = rp.getPositionForOffset(local).offset;
    // getPositionForOffset returns a caret position; pick the character whose box holds the tap.
    for (final j in [i, i - 1]) {
      if (j < 0 || j >= text.length || text[j] == '\n') continue;
      final hit = rp
          .getBoxesForSelection(
            TextSelection(baseOffset: j, extentOffset: j + 1),
            boxHeightStyle: BoxHeightStyle.max,
          )
          .any((b) => b.toRect().inflate(2).contains(local));
      if (hit) return widget.onTapChar?.call(j);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final s = widget.style;
    final h = widget.highlight;
    final hl = Theme.of(context).colorScheme.primary.withValues(alpha: 0.75);
    // The highlight goes on the bottom layer: with an outline that is the
    // stroke, so the looked-up word keeps its outline on top of the gold.
    List<InlineSpan> spans({required bool withHighlight}) =>
        h == null || h.$1 >= text.length
        ? [TextSpan(text: text)]
        : [
            TextSpan(text: text.substring(0, h.$1)),
            TextSpan(
              text: text.substring(h.$1, (h.$1 + h.$2).clamp(0, text.length)),
              style: withHighlight ? TextStyle(backgroundColor: hl) : null,
            ),
            TextSpan(text: text.substring((h.$1 + h.$2).clamp(0, text.length))),
          ];
    final outlined = s.backdrop == SubtitleBackdrop.outline;
    final weight = s.bold ? FontWeight.w700 : FontWeight.w500;
    final fill = Text.rich(
      TextSpan(
        style: TextStyle(
          color: s.color,
          fontSize: s.size,
          height: 1.35,
          fontWeight: weight,
          // A soft shadow helps every style except the box, which is readable on its own.
          shadows: s.backdrop == SubtitleBackdrop.box
              ? null
              : const [Shadow(blurRadius: 4), Shadow(blurRadius: 2)],
        ),
        children: spans(withHighlight: !outlined),
      ),
      key: _key,
      textAlign: TextAlign.center,
    );
    // Outline: the same text stroked in black underneath the fill.
    final outline = !outlined
        ? null
        : Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: s.size,
                height: 1.35,
                fontWeight: weight,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = s.size * 0.16
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.black,
              ),
              children: spans(withHighlight: true),
            ),
            textAlign: TextAlign.center,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapChar == null ? null : _onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: s.backdrop == SubtitleBackdrop.box
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: s.boxOpacity),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: outline == null
            ? fill
            : Stack(alignment: Alignment.center, children: [outline, fill]),
      ),
    );
  }
}
