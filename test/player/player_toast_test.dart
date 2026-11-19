import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/player/player_toast.dart';

void main() {
  testWidgets('a message drops in, is replaced, then goes away', (t) async {
    final toast = PlayerToast();
    addTearDown(toast.dispose);
    await t.pumpWidget(MaterialApp(home: PlayerToastView(toast)));

    toast.show('First');
    await t.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);

    toast.show('Second', duration: const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('the action runs and closes the message', (t) async {
    final toast = PlayerToast();
    addTearDown(toast.dispose);
    var undone = false;
    await t.pumpWidget(MaterialApp(home: PlayerToastView(toast)));
    toast.show(
      'Synced',
      action: SnackBarAction(label: 'Undo', onPressed: () => undone = true),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.text('Synced'), findsNothing);
  });
}
