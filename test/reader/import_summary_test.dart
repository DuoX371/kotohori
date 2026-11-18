import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/shelf_screen.dart';

void main() {
  test('a bulk import is summed up in one line', () {
    expect(
      importSummary(added: 5, existed: 2, failed: 1),
      "Added 5 books · 2 already on your shelf · 1 couldn't be opened",
    );
    expect(importSummary(added: 1, existed: 0, failed: 0), 'Added 1 book');
    expect(
      importSummary(added: 0, existed: 3, failed: 0),
      '3 already on your shelf',
    );
    expect(
      importSummary(added: 0, existed: 0, failed: 2),
      "2 couldn't be opened",
    );
  });
}
