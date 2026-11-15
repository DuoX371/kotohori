import 'package:flutter/material.dart';

/// What the double-tap feedback shows; [pulse] changes on every tap so the
/// ripple and arrows replay.
typedef SeekFlashData = ({bool forward, int seconds, Offset at, int pulse});

/// YouTube-style double-tap feedback: a soft arc on the tapped side, a ripple
/// from the finger, three arrows lighting up in turn, and the running total.
class SeekFlash extends StatelessWidget {
  const SeekFlash(this.data, {super.key, required this.visible});
  final SeekFlashData data;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width * 0.4, h = size.height;
    final f = data.forward;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: visible ? 120 : 300),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: f ? null : 0,
              right: f ? 0 : null,
              width: w,
              child: ClipRRect(
                // The inner edge bulges towards the middle, like YouTube's arc.
                borderRadius: f
                    ? BorderRadius.horizontal(
                        left: Radius.elliptical(w * 0.7, h),
                      )
                    : BorderRadius.horizontal(
                        right: Radius.elliptical(w * 0.7, h),
                      ),
                child: ColoredBox(
                  color: const Color(0x26FFFFFF),
                  child: Stack(
                    children: [
                      _Ripple(
                        key: ValueKey(data.pulse),
                        // Tap point, relative to the arc.
                        at: data.at - Offset(f ? size.width - w : 0, 0),
                      ),
                      Center(child: _Label(data)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ripple extends StatelessWidget {
  const _Ripple({super.key, required this.at});
  final Offset at;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (_, t, _) {
      final r = 40 + 110 * t;
      return Positioned(
        left: at.dx - r,
        top: at.dy - r,
        width: r * 2,
        height: r * 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22 * (1 - t)),
          ),
        ),
      );
    },
  );
}

class _Label extends StatelessWidget {
  const _Label(this.data);
  final SeekFlashData data;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Three arrows light up one after another (replays on each tap).
      TweenAnimationBuilder<double>(
        key: ValueKey(('arrows', data.pulse)),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (_, t, _) => Transform.flip(
          flipX: !data.forward,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Opacity(
                  opacity: (1 - ((t * 3 - i) - 0.5).abs()).clamp(0.3, 1.0),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 2),
      // Compact "10s"; the count pops slightly each time it grows.
      TweenAnimationBuilder<double>(
        key: ValueKey(('count', data.pulse)),
        tween: Tween(begin: 1.18, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Text(
          '${data.seconds}s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            fontFeatures: [FontFeature.tabularFigures()],
            shadows: [Shadow(blurRadius: 6, color: Color(0x99000000))],
          ),
        ),
      ),
    ],
  );
}
