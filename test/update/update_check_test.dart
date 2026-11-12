import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/update/update_check.dart';

void main() {
  test('compares versions numerically', () {
    expect(compareVersions('v0.2.0', '0.1.0'), greaterThan(0));
    expect(compareVersions('0.1.10', '0.1.9'), greaterThan(0));
    expect(compareVersions('v0.1.0', '0.1.0'), 0);
    expect(compareVersions('0.1', '0.1.0'), 0);
    expect(compareVersions('1.0.0+5', '1.0.0'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), lessThan(0));
  });
}
