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

class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get servingDesc => text().nullable()();
  // New metadata for external sources
  TextColumn get barcode => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('custom'))(); // custom|off
  TextColumn get remoteId => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
  RealColumn get servingQty => real().nullable()();
  TextColumn get servingUnit => text().nullable()();
  // Macros per serving
  IntColumn get proteinG => integer().withDefault(const Constant(0))();
  IntColumn get carbsG => integer().withDefault(const Constant(0))();
  IntColumn get fatsG => integer().withDefault(const Constant(0))();
  IntColumn get calories => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  // Store date at local midnight
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // breakfast|lunch|dinner|snack
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer().customConstraint('NOT NULL REFERENCES meals(id) ON DELETE CASCADE')();
  IntColumn get foodId => integer().customConstraint('NOT NULL REFERENCES foods(id) ON DELETE CASCADE')();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  IntColumn get proteinG => integer().withDefault(const Constant(0))();
  IntColumn get carbsG => integer().withDefault(const Constant(0))();
  IntColumn get fatsG => integer().withDefault(const Constant(0))();
  IntColumn get calories => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MealTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MealTemplateItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().customConstraint('NOT NULL REFERENCES meal_templates(id) ON DELETE CASCADE')();
  IntColumn get foodId => integer().customConstraint('NOT NULL REFERENCES foods(id) ON DELETE CASCADE')();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text().nullable()();
  IntColumn get sourceTemplateId => integer().nullable().customConstraint('NULL REFERENCES workout_templates(id) ON DELETE SET NULL')();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().customConstraint('NOT NULL REFERENCES workouts(id) ON DELETE CASCADE')();
  IntColumn get exerciseId => integer().customConstraint('NOT NULL REFERENCES exercises(id) ON DELETE CASCADE')();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId => integer().customConstraint('NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE')();
  IntColumn get setIndex => integer().withDefault(const Constant(1))();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().customConstraint('NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE')();
  TextColumn get exerciseName => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get setsCount => integer().withDefault(const Constant(3))();
  IntColumn get repsMin => integer().nullable()();
  IntColumn get repsMax => integer().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
}

class WorkoutSchedule extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  IntColumn get dayOfWeek => integer()(); // 1=Mon..7=Sun
  IntColumn get templateId => integer().customConstraint('NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE')();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TaskSchedule extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  IntColumn get taskId => integer().customConstraint('NOT NULL REFERENCES tasks(id) ON DELETE CASCADE')();
  IntColumn get dayOfWeek => integer()(); // 1=Mon..7=Sun
}

class TaskLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  IntColumn get taskId => integer().customConstraint('NOT NULL REFERENCES tasks(id) ON DELETE CASCADE')();
  DateTimeColumn get date => dateTime()(); // day resolution
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DriftDatabase(
  tables: [
    Settings,
    Users,
    Goals,
    Foods,
    Meals,
    MealItems,
    MealTemplates,
    MealTemplateItems,
    Exercises,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    WorkoutTemplates,
    TemplateExercises,
    WorkoutSchedule,
    Tasks,
    TaskSchedule,
    TaskLog,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(foods);
            await m.createTable(meals);
            await m.createTable(mealItems);
          }
          if (from < 3) {
            await m.addColumn(foods, foods.barcode);
            await m.addColumn(foods, foods.source);
            await m.addColumn(foods, foods.remoteId);
            await m.addColumn(foods, foods.isCustom);
            await m.addColumn(foods, foods.servingQty);
            await m.addColumn(foods, foods.servingUnit);
          }
          if (from < 4) {
            await m.createTable(exercises);
            await m.createTable(workouts);
            await m.createTable(workoutExercises);
            await m.createTable(workoutSets);
          }
          if (from < 5) {
            await m.createTable(workoutTemplates);
            await m.createTable(templateExercises);
            await m.createTable(workoutSchedule);
            await m.addColumn(workouts, workouts.sourceTemplateId);
          }
          if (from < 6) {
            await m.addColumn(templateExercises, templateExercises.setsCount);
            await m.addColumn(templateExercises, templateExercises.repsMin);
            await m.addColumn(templateExercises, templateExercises.repsMax);
          }
          if (from < 7) {
            await m.addColumn(templateExercises, templateExercises.restSeconds);
          }
          if (from < 8) {
            // Add useful indexes for performance
            await m.createIndex(Index('idx_meals_date', 'CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date)'));
            await m.createIndex(Index('idx_meal_items_meal', 'CREATE INDEX IF NOT EXISTS idx_meal_items_meal ON meal_items(meal_id)'));
            await m.createIndex(Index('idx_workouts_started', 'CREATE INDEX IF NOT EXISTS idx_workouts_started ON workouts(started_at)'));
            await m.createIndex(Index('idx_workouts_template', 'CREATE INDEX IF NOT EXISTS idx_workouts_template ON workouts(source_template_id)'));
            await m.createIndex(Index('idx_workout_exercises_workout', 'CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout ON workout_exercises(workout_id)'));
            await m.createIndex(Index('idx_workout_sets_we', 'CREATE INDEX IF NOT EXISTS idx_workout_sets_we ON workout_sets(workout_exercise_id)'));
          }
          if (from < 9) {
            await m.createTable(this.tasks);
            await m.createTable(this.taskSchedule);
            await m.createTable(this.taskLog);
            await m.createIndex(Index('idx_task_schedule_day', 'CREATE INDEX IF NOT EXISTS idx_task_schedule_day ON task_schedule(day_of_week)'));
            await m.createIndex(Index('idx_task_log_date', 'CREATE INDEX IF NOT EXISTS idx_task_log_date ON task_log(date)'));
          }
          if (from < 10) {
            await m.createTable(this.mealTemplates);
            await m.createTable(this.mealTemplateItems);
            await m.createIndex(Index('idx_meal_template_items_template', 'CREATE INDEX IF NOT EXISTS idx_meal_template_items_template ON meal_template_items(template_id)'));
          }
        },
      );

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
