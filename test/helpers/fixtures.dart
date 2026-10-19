import 'dart:io';
import 'dart:typed_data';

/// Raw bytes of a file in `test/fixtures/csv/`.
Uint8List csvFixture(String name) =>
    File('test/fixtures/csv/$name').readAsBytesSync();

/// Raw bytes of a file in `test/fixtures/anki/` (written by the official
/// Anki library, see `tool/anki/make_fixtures.py`).
Uint8List ankiFixture(String name) =>
    File('test/fixtures/anki/$name').readAsBytesSync();
