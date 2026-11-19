import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/home/swipe_to_delete.dart';

void main() {
  Future<(List<String>, List<String>)> pump(WidgetTester t) async {
    final taps = <String>[], deletes = <String>[];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeToDelete(
            onDelete: () => deletes.add('x'),
            child: ListTile(
              title: const Text('Episode'),
              onTap: () => taps.add('x'),
            ),
          ),
        ),
      ),
    );
    return (taps, deletes);
  }

  testWidgets('swipe left shows Delete; tapping it deletes', (t) async {
    final (taps, deletes) = await pump(t);
    await t.drag(find.text('Episode'), const Offset(-200, 0));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pump(const Duration(milliseconds: 100));
    expect(deletes, isEmpty, reason: 'slides away first');
    await t.pumpAndSettle();
    expect(deletes, hasLength(1));
    expect(taps, isEmpty);
  });

  testWidgets('a tap on the open row covers Delete instead of opening', (
    t,
  ) async {
    final (taps, deletes) = await pump(t);
    await t.drag(find.text('Episode'), const Offset(-200, 0));
    await t.pumpAndSettle();
    // Lands on the cover over the row, not the row itself.
    await t.tap(find.text('Episode'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(taps, isEmpty);
    expect(find.text('Delete'), findsNothing);

    await t.tap(find.text('Episode'));
    expect(taps, hasLength(1));
    expect(deletes, isEmpty);
  });

  testWidgets('a short swipe springs back', (t) async {
    await pump(t);
    await t.timedDrag(
      find.text('Episode'),
      const Offset(-30, 0),
      const Duration(milliseconds: 500),
    );
    await t.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
  });
}
