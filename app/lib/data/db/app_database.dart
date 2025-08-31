import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text()();
  TextColumn get value => text()();
}

@DriftDatabase(tables: [Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> upsertSetting(String key, String value) async {
    final existing = await (select(settings)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    if (existing == null) {
      await into(settings).insert(SettingsCompanion.insert(key: key, value: value));
    } else {
      await (update(settings)..where((tbl) => tbl.id.equals(existing.id))).write(SettingsCompanion(value: Value(value)));
    }
  }

  Future<String?> readSetting(String key) async {
    final existing = await (select(settings)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return existing?.value;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationSupportDirectory();
    final String dbPath = p.join(dir.path, 'gymrat.db');
    // Use drift_sqflite for iOS/Android; fallback to NativeDatabase for others.
    if (Platform.isIOS || Platform.isAndroid) {
      final executor = SqfliteQueryExecutor(path: dbPath);
      return DatabaseConnection(executor);
    }
    return NativeDatabase(File(dbPath));
  });
}
