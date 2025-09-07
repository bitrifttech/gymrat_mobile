import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class ProfileGoals {
  final int? ageYears;
  final int? heightCm;
  final double? weightKg;
  final String? gender;
  final String? activityLevel;
  final int? caloriesMin;
  final int? caloriesMax;
  final int? proteinG;
  final int? carbsG;
  final int? fatsG;
  const ProfileGoals({
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.activityLevel,
    this.caloriesMin,
    this.caloriesMax,
    this.proteinG,
    this.carbsG,
    this.fatsG,
  });
}

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<ProfileGoals> load() async {
    final user = await (_db.select(_db.users)
          ..orderBy([(u) => OrderingTerm.desc(u.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    final goal = await (_db.select(_db.goals)
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return ProfileGoals(
      ageYears: user?.ageYears,
      heightCm: user?.heightCm,
      weightKg: user?.weightKg,
      gender: user?.gender,
      activityLevel: user?.activityLevel,
      caloriesMin: goal?.caloriesMin,
      caloriesMax: goal?.caloriesMax,
      proteinG: goal?.proteinG,
      carbsG: goal?.carbsG,
      fatsG: goal?.fatsG,
    );
  }

  Future<void> save(ProfileGoals pg) async {
    await _db.transaction(() async {
      final user = await (_db.select(_db.users)
            ..orderBy([(u) => OrderingTerm.desc(u.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (user == null) {
        final userId = await _db.into(_db.users).insert(UsersCompanion.insert(
              ageYears: Value(pg.ageYears),
              heightCm: Value(pg.heightCm),
              weightKg: Value(pg.weightKg),
              gender: Value(pg.gender),
              activityLevel: Value(pg.activityLevel),
            ));
        await _db.into(_db.goals).insert(GoalsCompanion.insert(
          userId: userId,
          caloriesMin: pg.caloriesMin ?? 2000,
          caloriesMax: pg.caloriesMax ?? 2200,
          proteinG: pg.proteinG ?? 150,
          carbsG: pg.carbsG ?? 250,
          fatsG: pg.fatsG ?? 70,
        ));
      } else {
        await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
          UsersCompanion(
            ageYears: Value(pg.ageYears),
            heightCm: Value(pg.heightCm),
            weightKg: Value(pg.weightKg),
            gender: Value(pg.gender),
            activityLevel: Value(pg.activityLevel),
          ),
        );
        await _db.into(_db.goals).insert(GoalsCompanion.insert(
          userId: user.id,
          caloriesMin: pg.caloriesMin ?? 2000,
          caloriesMax: pg.caloriesMax ?? 2200,
          proteinG: pg.proteinG ?? 150,
          carbsG: pg.carbsG ?? 250,
          fatsG: pg.fatsG ?? 70,
        ));
      }
    });
  }

  Future<String> getUnits() async {
    return await _db.readSetting('units') ?? 'metric';
    }

  Future<void> setUnits(String units) async {
    await _db.upsertSetting('units', units);
  }

  Future<void> resetAll() async {
    await _db.transaction(() async {
      // Delete child tables first to satisfy FKs
      await _db.customStatement('DELETE FROM workout_sets');
      await _db.customStatement('DELETE FROM workout_exercises');
      await _db.customStatement('DELETE FROM template_exercises');
      await _db.customStatement('DELETE FROM meal_items');
      // Delete parents
      await _db.customStatement('DELETE FROM workouts');
      await _db.customStatement('DELETE FROM exercises');
      await _db.customStatement('DELETE FROM workout_schedule');
      await _db.customStatement('DELETE FROM workout_templates');
      await _db.customStatement('DELETE FROM meals');
      await _db.customStatement('DELETE FROM foods');
      // Users/goals/settings last (goals cascades from users, but we clear both)
      await _db.customStatement('DELETE FROM goals');
      await _db.customStatement('DELETE FROM users');
      await _db.customStatement('DELETE FROM settings');
      // Optional: reset autoincrement counters
      await _db.customStatement('DELETE FROM sqlite_sequence');
      // Prevent demo reseed on next launch
      await _db.upsertSetting('demoSeeded', 'true');
    });
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return SettingsRepository(db);
});

final profileGoalsProvider = FutureProvider<ProfileGoals>((ref) async {
  return ref.read(settingsRepositoryProvider).load();
});

final unitsProvider = FutureProvider<String>((ref) async {
  return ref.read(settingsRepositoryProvider).getUnits();
});
