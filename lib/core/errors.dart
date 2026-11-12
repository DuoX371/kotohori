class DictionaryException implements Exception {
  DictionaryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DuplicateDictionaryException extends DictionaryException {
  DuplicateDictionaryException(this.title, String revision)
    : super('"$title" rev.$revision is already installed');
  final String title;
}

class InvalidDictionaryException extends DictionaryException {
  InvalidDictionaryException(super.message);
}

class InsufficientStorageException extends DictionaryException {
  InsufficientStorageException(int needed, int free)
    : super(
        'Not enough free space: need ~${needed >> 20} MB, have ${free >> 20} MB',
      );
}
