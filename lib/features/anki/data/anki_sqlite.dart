import 'dart:math';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:typed_data/typed_buffers.dart';

/// Runs [body] on an SQLite database held entirely in memory (a private
/// in-memory virtual file system), optionally starting from [initial]
/// bytes. Returns the body's result and the database file's final bytes.
/// Nothing touches the device's file system.
(T, Uint8List) withMemoryDatabase<T>(
  T Function(Database db) body, {
  Uint8List? initial,
}) {
  final name = 'aiwb-${Random().nextInt(1 << 32)}';
  const path = '/collection.db';
  final fs = InMemoryFileSystem(name: name);
  if (initial != null) fs.fileData[path] = Uint8Buffer()..addAll(initial);
  sqlite3.registerVirtualFileSystem(fs);
  try {
    final db = sqlite3.open(
      path,
      vfs: name,
      mode: initial == null ? OpenMode.readWriteCreate : OpenMode.readOnly,
    );
    final T result;
    try {
      result = body(db);
    } finally {
      db.close();
    }
    final data = fs.fileData[path];
    return (
      result,
      data == null
          ? Uint8List(0)
          : Uint8List.fromList(data.buffer.asUint8List(0, data.length)),
    );
  } finally {
    sqlite3.unregisterVirtualFileSystem(fs);
  }
}
