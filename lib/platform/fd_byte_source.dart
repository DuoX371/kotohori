import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../features/subtitles/mkv/mkv_reader.dart' show ByteSource;

typedef _PreadC = IntPtr Function(
  Int32 fd,
  Pointer<Uint8> buf,
  IntPtr count,
  Int64 offset,
);
typedef _PreadDart = int Function(
  int fd,
  Pointer<Uint8> buf,
  int count,
  int offset,
);

/// Reads an already-open file descriptor with libc `pread64`.
///
/// Android won't let the app reopen a picked file via `/proc/self/fd/N`
/// (the storage layer checks the path), but the descriptor ContentResolver
/// handed us is readable directly.
class FdByteSource implements ByteSource {
  FdByteSource(this.fd, this.length);
  final int fd;
  @override
  final int length;

  static final _pread = DynamicLibrary.process()
      .lookupFunction<_PreadC, _PreadDart>('pread64');

  @override
  Uint8List read(int offset, int count) {
    if (count <= 0 || offset >= length) return Uint8List(0);
    final buf = malloc<Uint8>(count);
    try {
      final n = _pread(fd, buf, count, offset);
      if (n < 0) throw const FileSystemException('Reading the video failed');
      return Uint8List.fromList(buf.asTypedList(n));
    } finally {
      malloc.free(buf);
    }
  }
}
