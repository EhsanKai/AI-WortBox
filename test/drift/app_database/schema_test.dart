import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

// Verifies that the schema created by the app matches the exported schema
// files in drift_schemas/. When the schema version is bumped, run
// `dart run drift_dev make-migrations` to export the new version and
// generate step-by-step migration tests next to this file.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a fresh install matches exported schema v2', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);
  });

  test('latest exported schema equals the app schema version', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(GeneratedHelper.versions.last, db.schemaVersion);
  });
}
