import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/book_stats.dart';

void main() {
  test('durations read like "3 h 20 min"', () {
    expect(durationLabel(const Duration(hours: 3, minutes: 20)), '3 h 20 min');
    expect(durationLabel(const Duration(hours: 2)), '2 h');
    expect(durationLabel(const Duration(minutes: 45, seconds: 40)), '46 min');
    expect(durationLabel(const Duration(seconds: 20)), '< 1 min');
  });

  test('characters read: chapters before plus the offset', () {
    expect(charsRead([100, 200, 300], chapter: 2, offset: 50), 350);
    expect(charsRead([100], chapter: 5, offset: 0), 100);
  });

  test('the learnt pace leans on history, moves with new sessions', () {
    expect(blendPace(null, 400), 400);
    expect(blendPace(300, 400), 330);
  });

  test('numbers get thousands separators', () {
    expect(grouped(98000), '98,000');
    expect(grouped(950), '950');
  });
}
