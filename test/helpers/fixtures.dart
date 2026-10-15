import 'dart:io';
import 'dart:typed_data';

/// Raw bytes of a file in `test/fixtures/csv/`.
Uint8List csvFixture(String name) =>
    File('test/fixtures/csv/$name').readAsBytesSync();
