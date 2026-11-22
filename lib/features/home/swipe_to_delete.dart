import 'package:flutter/material.dart';

class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
    this.label = 'Delete',
    this.gap = 0,
  });
  final Widget child;
  final VoidCallback onDelete;
  final String label;

  final double gap;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with TickerProviderStateMixin {
  static const _width = 104.0;

  /// A deeper red than the theme's error colour, which is pale in dark mode.
  static const _red = Color(0xFFC6403F);

  /// 0 = covered, 1 = Delete fully showing.
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  /// Delete pressed: the row fades and shrinks away while the rows below
  /// glide up into its place, like books on the reader's shelf.
  late final _gone = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  Future<void> _delete() async {
    if (!MediaQuery.disableAnimationsOf(context)) await _gone.forward();
    widget.onDelete();
  }

  @override
  void dispose() {
    _gone.dispose();
    _open.dispose();
    super.dispose();
  }

  void _settle(double velocity) {
    final open = velocity < -300 || (velocity <= 300 && _open.value > 0.5);
    _open.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _open.value -= d.primaryDelta! / _width,
      onHorizontalDragEnd: (d) => _settle(d.primaryVelocity ?? 0),
      child: SizeTransition(
        alignment: Alignment.topCenter,
        sizeFactor: Tween(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _gone,
            curve: const Interval(0.2, 1, curve: Curves.easeInOutCubic),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.gap),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: _gone,
                curve: const Interval(0, 0.45, curve: Curves.easeOut),
              ),
            ),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.9).animate(
                CurvedAnimation(
                  parent: _gone,
                  curve: const Interval(0, 0.45, curve: Curves.easeOut),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      // Hidden while covered, so no red shows at the rounded corners.
                      child: ValueListenableBuilder(
                        valueListenable: _open,
                        builder: (context, v, child) =>
                            Visibility(visible: v > 0, child: child!),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: _width,
                            child: Material(
                              color: _red,
                              child: InkWell(
                                onTap: _gone.isAnimating ? null : _delete,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.label,
                                      style: t.textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _open,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(-_open.value * _width, 0),
                        child: child,
                      ),
                      child: widget.child,
                    ),
                    // While open, a tap on the row only covers Delete again.
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: _width,
                      child: ValueListenableBuilder(
                        valueListenable: _open,
                        builder: (context, v, child) =>
                            IgnorePointer(ignoring: v == 0, child: child),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _open.animateTo(0, curve: Curves.easeOutCubic),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
