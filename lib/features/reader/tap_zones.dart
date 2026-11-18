import 'dart:math' as math;

/// What a tap on blank space does (a tap on a word always looks it up).
enum BlankTapAction { next, previous, menu }

/// Each side strip is this share of the page width…
const double tapStripFraction = 0.10;

/// …but never narrower than a fingertip (on a phone 10% is only ~40 dp).
const double tapStripMinDp = 48;

/// Height of the band along the top where blank space always shows or hides
/// the menu (it's where the menu appears), corners included: the same rule
/// as the side strips, applied to the page height.
double topBandDp(double height) =>
    math.max(height * tapStripFraction, tapStripMinDp);

/// Width of each side strip on a page [width] dp wide.
double sideStripDp(double width) =>
    math.max(width * tapStripFraction, tapStripMinDp);

/// Blank space at ([x], [y]) (0..1 across a page [width] × [height] dp): the
/// top band shows or hides the menu; below it the side strips turn the page;
/// the rest shows or hides the menu. Vertical books read right to left, so
/// their next page is on the left; horizontal books the opposite. With
/// [height] unknown (0) there is no top band.
BlankTapAction blankTapAction(
  double x,
  double width, {
  double y = 0.5,
  double height = 0,
  required bool vertical,
}) {
  if (width <= 0) return BlankTapAction.menu;
  if (height > 0 && y * height <= topBandDp(height)) {
    return BlankTapAction.menu;
  }
  final strip = sideStripDp(width);
  final dx = x * width;
  final left = dx <= strip, right = dx >= width - strip;
  if (left) return vertical ? BlankTapAction.next : BlankTapAction.previous;
  if (right) return vertical ? BlankTapAction.previous : BlankTapAction.next;
  return BlankTapAction.menu;
}
