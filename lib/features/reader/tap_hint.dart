import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tap_zones.dart';

String _seenKey(bool vertical) =>
    'reader.hintSeen.${vertical ? 'vertical' : 'horizontal'}';

bool tapHintDue(SharedPreferences prefs, {required bool vertical}) =>
    !(prefs.getBool(_seenKey(vertical)) ?? false);

Future<void> markTapHintSeen(
  SharedPreferences prefs, {
  required bool vertical,
}) => prefs.setBool(_seenKey(vertical), true);

class TapHint extends StatefulWidget {
  const TapHint({
    super.key,
    required this.vertical,
    required this.color,
    required this.background,
    required this.onDone,
  });

  final bool vertical;
  final Color color;
  final Color background;
  final VoidCallback onDone;

  static const visible = Duration(milliseconds: 2500);
  static const fade = Duration(milliseconds: 800);

  @override
  State<TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<TapHint> with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: TapHint.fade,
    value: 1,
  );
  Timer? _wait;

  @override
  void initState() {
    super.initState();
    _wait = Timer(TapHint.visible, () {
      _fade.reverse().whenComplete(() {
        if (mounted) widget.onDone();
      });
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _fade.dispose();
    super.dispose();
  }

  Widget _label(Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: widget.background.withValues(alpha: 0.95),
      border: Border.all(color: widget.color.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    ),
  );

  Widget _strip(String side, bool next) {
    final c = widget.color;
    final arrow = side == 'left' ? Icons.chevron_left : Icons.chevron_right;
    return ColoredBox(
      key: ValueKey('tap-hint-$side'),
      color: c.withValues(alpha: 0.12),
      child: Center(
        child: _label(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(arrow, color: c, size: 28),
              Text(next ? 'Next' : 'Previous', style: TextStyle(color: c)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _fade,
        child: LayoutBuilder(
          builder: (context, box) {
            final strip = sideStripDp(box.maxWidth);
            final top = topBandDp(box.maxHeight);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: strip,
                  child: Padding(
                    padding: EdgeInsets.only(top: top),
                    child: _strip('left', widget.vertical),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _label(
                      Text(
                        'Tap a word to look it up',
                        style: TextStyle(color: widget.color, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: strip,
                  child: Padding(
                    padding: EdgeInsets.only(top: top),
                    child: _strip('right', !widget.vertical),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
