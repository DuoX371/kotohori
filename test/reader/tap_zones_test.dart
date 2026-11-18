import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/tap_zones.dart';

void main() {
  BlankTapAction v(double x, double width) =>
      blankTapAction(x, width, vertical: true);
  BlankTapAction h(double x, double width) =>
      blankTapAction(x, width, vertical: false);

  test('tablet: the outer 10% turns pages, the middle toggles the bar', () {
    expect(v(0.05, 1204), BlankTapAction.next); // vertical: left is next
    expect(v(0.95, 1204), BlankTapAction.previous);
    expect(v(0.5, 1204), BlankTapAction.menu);
    expect(h(0.05, 1204), BlankTapAction.previous); // horizontal: right is next
    expect(h(0.95, 1204), BlankTapAction.next);
  });

  test('a tap right on the strip edge counts as the strip', () {
    expect(v(0.10, 1000), BlankTapAction.next);
    expect(v(0.90, 1000), BlankTapAction.previous);
    expect(v(0.1001, 1000), BlankTapAction.menu);
  });

  test('narrow screens: strips are at least 48 dp wide', () {
    expect(v(45 / 400, 400), BlankTapAction.next); // 10% would be 40 dp
    expect(v(50 / 400, 400), BlankTapAction.menu);
    expect(v(355 / 400, 400), BlankTapAction.previous);
  });

  test('the top band always shows the menu, even in the corners', () {
    // 1204 x 675 page: band = max(67.5, 48) = 67.5 dp.
    BlankTapAction at(double x, double y, {bool vertical = true}) =>
        blankTapAction(x, 1204, y: y, height: 675, vertical: vertical);
    expect(at(0.05, 60 / 675), BlankTapAction.menu); // top left
    expect(at(0.95, 60 / 675), BlankTapAction.menu); // top right
    expect(at(0.05, 67.5 / 675), BlankTapAction.menu); // on the band edge
    expect(at(0.05, 70 / 675), BlankTapAction.next); // just below it
    expect(at(0.95, 0.5, vertical: false), BlankTapAction.next);
    // A short page (phone landscape): the band is at least 48 dp.
    expect(
      blankTapAction(0.05, 800, y: 45 / 300, height: 300, vertical: true),
      BlankTapAction.menu,
    );
    // Height unknown (old messages): no band.
    expect(v(0.05, 1204), BlankTapAction.next);
  });

  test('unknown page width: the middle', () {
    expect(v(0.01, 0), BlankTapAction.menu);
    expect(v(0.99, 0), BlankTapAction.menu);
  });
}
