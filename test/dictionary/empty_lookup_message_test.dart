import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart';

Dictionary dict({required bool enabled}) => Dictionary(
  id: 1,
  title: 'Jitendex',
  revision: '1',
  format: 3,
  isUpdatable: false,
  stylesCss: '',
  enabled: enabled,
  priority: 0,
);

void main() {
  Future<String> messageFor(List<Dictionary> dicts) async {
    final c = ProviderContainer(
      overrides: [installedProvider.overrideWithValue(AsyncData(dicts))],
    );
    addTearDown(c.dispose);
    return c.read(emptyLookupMessageProvider);
  }

  test('says why a lookup is empty', () async {
    expect(await messageFor([]), contains('No dictionaries installed'));
    expect(
      await messageFor([dict(enabled: false)]),
      contains('currently enabled'),
    );
    expect(await messageFor([dict(enabled: true)]), 'No results');
  });
}
