import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  Future<int> _getCurrentUserId() async {
    final u = await (_db.select(_db.users)
          ..orderBy([(u) => OrderingTerm.asc(u.id)])
          ..limit(1))
        .getSingleOrNull();
    if (u == null) throw StateError('No user found. Complete onboarding.');
    return u.id;
  }

  Future<int> startWorkout({String? name}) async {
    final userId = await _getCurrentUserId();
    return _db.into(_db.workouts).insert(WorkoutsCompanion.insert(
      userId: userId,
      name: Value(name),
    ));
  }

  Future<void> finishWorkout(int workoutId) async {
    await (_db.update(_db.workouts)..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        finishedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> ensureExerciseByName(String name) async {
    final userId = await _getCurrentUserId();
    final existing = await (_db.select(_db.exercises)
          ..where((e) => e.userId.equals(userId) & e.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.exercises).insert(ExercisesCompanion.insert(userId: userId, name: name));
  }

  Future<int> addExerciseToWorkout({required int workoutId, required String exerciseName}) async {
    final exerciseId = await ensureExerciseByName(exerciseName.trim());
    final current = await (_db.select(_db.workoutExercises)
          ..where((we) => we.workoutId.equals(workoutId))
          ..orderBy([(we) => OrderingTerm.desc(we.orderIndex)])
          ..limit(1))
        .getSingleOrNull();
    final nextIndex = (current?.orderIndex ?? -1) + 1;
    return _db.into(_db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
      workoutId: workoutId,
      exerciseId: exerciseId,
      orderIndex: Value(nextIndex),
    ));
  }

  Future<int> addSet({required int workoutExerciseId, double? weight, int? reps}) async {
    final current = await (_db.select(_db.workoutSets)
          ..where((ws) => ws.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(ws) => OrderingTerm.desc(ws.setIndex)])
          ..limit(1))
        .getSingleOrNull();
    final nextIndex = (current?.setIndex ?? 0) + 1;
    return _db.into(_db.workoutSets).insert(WorkoutSetsCompanion.insert(
      workoutExerciseId: workoutExerciseId,
      setIndex: Value(nextIndex),
      weight: Value(weight),
      reps: Value(reps),
    ));
  }

  Stream<Workout?> watchActiveWorkout() {
    final query = (_db.select(_db.workouts)
      ..where((w) => w.finishedAt.isNull())
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
      ..limit(1));
    return query.watchSingleOrNull();
  }

  Stream<List<(WorkoutExercise, Exercise)>> watchWorkoutExercises(int workoutId) {
    final query = (_db.select(_db.workoutExercises)
      ..where((we) => we.workoutId.equals(workoutId))
      ..orderBy([(we) => OrderingTerm.asc(we.orderIndex)]));
    return query.watch().asyncMap((exs) async {
      final pairs = <(WorkoutExercise, Exercise)>[];
      for (final we in exs) {
        final ex = await (_db.select(_db.exercises)..where((e) => e.id.equals(we.exerciseId))).getSingle();
        pairs.add((we, ex));
      }
      return pairs;
    });
  }

  Stream<List<WorkoutSet>> watchSetsForWorkoutExercise(int workoutExerciseId) {
    final query = (_db.select(_db.workoutSets)
      ..where((ws) => ws.workoutExerciseId.equals(workoutExerciseId))
      ..orderBy([(ws) => OrderingTerm.asc(ws.setIndex)]));
    return query.watch();
  }

  Stream<List<Workout>> watchWorkoutHistory({int limit = 20}) {
    final q = (_db.select(_db.workouts)
      ..where((w) => w.finishedAt.isNotNull())
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
      ..limit(limit));
    return q.watch();
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return WorkoutRepository(db);
});

final activeWorkoutProvider = StreamProvider<Workout?>((ref) {
  return ref.read(workoutRepositoryProvider).watchActiveWorkout();
});

final workoutExercisesProvider = StreamProvider.family<List<(WorkoutExercise, Exercise)>, int>((ref, workoutId) {
  return ref.read(workoutRepositoryProvider).watchWorkoutExercises(workoutId);
});

final workoutExerciseSetsProvider = StreamProvider.family<List<WorkoutSet>, int>((ref, workoutExerciseId) {
  return ref.read(workoutRepositoryProvider).watchSetsForWorkoutExercise(workoutExerciseId);
});

final workoutHistoryProvider = StreamProvider<List<Workout>>((ref) {
  return ref.read(workoutRepositoryProvider).watchWorkoutHistory();
});
