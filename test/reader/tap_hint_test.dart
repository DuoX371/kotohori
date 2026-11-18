import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/tap_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the hint is due once per text direction', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    expect(tapHintDue(p, vertical: true), isTrue);
    expect(tapHintDue(p, vertical: false), isTrue);
    await markTapHintSeen(p, vertical: true);
    expect(tapHintDue(p, vertical: true), isFalse);
    expect(tapHintDue(p, vertical: false), isTrue);
    await markTapHintSeen(p, vertical: false);
    expect(tapHintDue(p, vertical: false), isFalse);
  });

  Future<int Function()> hint(
    WidgetTester t, {
    required bool vertical,
    double width = 800,
  }) async {
    var done = 0;
    t.view.physicalSize = Size(width, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: TapHint(
          vertical: vertical,
          color: Colors.black,
          background: Colors.white,
          onDone: () => done++,
        ),
      ),
    );
    return () => done;
  }

  testWidgets('labels sit on the right sides', (t) async {
    await hint(t, vertical: true);
    expect(t.getCenter(find.text('Next')).dx, lessThan(400));
    expect(t.getCenter(find.text('Previous')).dx, greaterThan(400));
    expect(find.text('Tap a word to look it up'), findsOneWidget);
    await hint(t, vertical: false);
    expect(t.getCenter(find.text('Next')).dx, greaterThan(400));
    expect(t.getCenter(find.text('Previous')).dx, lessThan(400));
  });

  testWidgets('strips are the real tap zones', (t) async {
    await hint(t, vertical: true);
    expect(t.getSize(find.byKey(const ValueKey('tap-hint-left'))).width, 80);
    await hint(t, vertical: true, width: 400);
    expect(t.getSize(find.byKey(const ValueKey('tap-hint-left'))).width, 48);
    expect(t.getSize(find.byKey(const ValueKey('tap-hint-right'))).width, 48);
  });

  testWidgets('side strips start below the top band', (t) async {
    await hint(t, vertical: true); // 800 x 600: band = max(60, 48) = 60
    final strip = t.getRect(find.byKey(const ValueKey('tap-hint-left')));
    expect(strip.top, 60);
    expect(strip.bottom, 600);
  });

  testWidgets('fades out and reports done once', (t) async {
    final done = await hint(t, vertical: true);
    await t.pump(const Duration(milliseconds: 2400));
    expect(done(), 0);
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 900));
    expect(done(), 1);
    await t.pump(const Duration(seconds: 5));
    expect(done(), 1);
  });
}
