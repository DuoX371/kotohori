import 'dart:async';

import 'package:flutter/material.dart';

typedef ToastMessage = ({String text, SnackBarAction? action});

/// The player's short messages ("Fill screen", "Synced…"). They drop in under
/// the top bar so they never cover the play controls at the bottom.
class PlayerToast extends ValueNotifier<ToastMessage?> {
  PlayerToast() : super(null);

  Timer? _timer;

  void show(
    String text, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _timer?.cancel();
    value = (text: text, action: action);
    _timer = Timer(duration, hide);
  }

  void hide() {
    _timer?.cancel();
    value = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// A dark card under the top bar; slides down and fades in, back up on hide.
class PlayerToastView extends StatelessWidget {
  const PlayerToastView(this.toast, {super.key});
  final PlayerToast toast;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder(
      valueListenable: toast,
      builder: (context, m, _) => AnimatedSwitcher(
        duration: Duration(milliseconds: still ? 0 : 240),
        reverseDuration: Duration(milliseconds: still ? 0 : 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, a) => SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(a),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: m == null
            ? const SizedBox.shrink()
            : ConstrainedBox(
                // A new message replaces the old one with the same motion.
                key: ObjectKey(m),
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: t.colorScheme.surfaceContainerHigh,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: t.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      m.action == null ? 20 : 8,
                      14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            m.text,
                            style: t.textTheme.bodyLarge?.copyWith(
                              color: t.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (m.action case final a?)
                          TextButton(
                            onPressed: () {
                              toast.hide();
                              a.onPressed();
                            },
                            child: Text(a.label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
