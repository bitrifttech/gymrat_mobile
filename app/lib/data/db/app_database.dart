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

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  IntColumn get ageYears => integer().nullable()();
  IntColumn get heightCm => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get activityLevel => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  IntColumn get caloriesMin => integer()();
  IntColumn get caloriesMax => integer()();
  IntColumn get proteinG => integer()();
  IntColumn get carbsG => integer()();
  IntColumn get fatsG => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Settings, Users, Goals])
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

  Future<bool> hasAnyUser() async {
    final countExp = users.id.count();
    final row = await (selectOnly(users)..addColumns([countExp])).map((r) => r.read(countExp)).getSingle();
    return (row ?? 0) > 0;
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
