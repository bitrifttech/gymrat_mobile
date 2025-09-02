import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<int> _getCurrentUserId() async {
    final u = await (_db.select(_db.users)
          ..orderBy([(u) => OrderingTerm.asc(u.id)])
          ..limit(1))
        .getSingleOrNull();
    if (u == null) throw StateError('No user found. Complete onboarding.');
    return u.id;
  }

  // ----- Active workout flow -----

  Future<int> startWorkout({String? name, int? sourceTemplateId}) async {
    final userId = await _getCurrentUserId();
    return _db.into(_db.workouts).insert(WorkoutsCompanion.insert(
      userId: userId,
      name: Value(name),
      sourceTemplateId: Value(sourceTemplateId),
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

  Future<void> upsertSetByIndex({
    required int workoutExerciseId,
    required int setIndex,
    double? weight,
    int? reps,
  }) async {
    final existing = await (_db.select(_db.workoutSets)
          ..where((ws) => ws.workoutExerciseId.equals(workoutExerciseId) & ws.setIndex.equals(setIndex))
          ..limit(1))
        .getSingleOrNull();
    final comp = WorkoutSetsCompanion(
      weight: Value(weight),
      reps: Value(reps),
    );
    if (existing == null) {
      await _db.into(_db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: workoutExerciseId,
            setIndex: Value(setIndex),
            weight: Value(weight),
            reps: Value(reps),
          ));
    } else {
      await (_db.update(_db.workoutSets)
            ..where((ws) => ws.id.equals(existing.id)))
          .write(comp);
    }
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

  // ----- Templates & Schedule -----

  Future<int> createTemplate(String name) async {
    final userId = await _getCurrentUserId();
    return _db.into(_db.workoutTemplates).insert(WorkoutTemplatesCompanion.insert(userId: userId, name: name));
  }

  Future<void> deleteTemplate(int templateId) async {
    await (_db.delete(_db.workoutTemplates)..where((t) => t.id.equals(templateId))).go();
  }

  Future<int> addTemplateExercise({required int templateId, required String exerciseName}) async {
    final current = await (_db.select(_db.templateExercises)
          ..where((te) => te.templateId.equals(templateId))
          ..orderBy([(te) => OrderingTerm.desc(te.orderIndex)])
          ..limit(1))
        .getSingleOrNull();
    final nextIndex = (current?.orderIndex ?? -1) + 1;
    return _db.into(_db.templateExercises).insert(TemplateExercisesCompanion.insert(
      templateId: templateId,
      exerciseName: exerciseName.trim(),
      orderIndex: Value(nextIndex),
    ));
  }

  Future<void> updateTemplateExerciseTargets({
    required int templateExerciseId,
    required int setsCount,
    int? repsMin,
    int? repsMax,
    int? restSeconds,
  }) async {
    await (_db.update(_db.templateExercises)..where((te) => te.id.equals(templateExerciseId))).write(
      TemplateExercisesCompanion(
        setsCount: Value(setsCount),
        repsMin: Value(repsMin),
        repsMax: Value(repsMax),
        restSeconds: restSeconds == null ? const Value.absent() : Value(restSeconds),
      ),
    );
  }

  Stream<List<WorkoutTemplate>> watchTemplates() {
    final userIdFuture = _getCurrentUserId();
    return Stream.fromFuture(userIdFuture).asyncExpand((userId) {
      return (_db.select(_db.workoutTemplates)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();
    });
  }

  Stream<List<TemplateExercise>> watchTemplateExercises(int templateId) {
    final q = (_db.select(_db.templateExercises)
      ..where((te) => te.templateId.equals(templateId))
      ..orderBy([(te) => OrderingTerm.asc(te.orderIndex)]));
    return q.watch();
  }

  Future<void> setSchedule({required int dayOfWeek, required int templateId}) async {
    final userId = await _getCurrentUserId();
    final existing = await (_db.select(_db.workoutSchedule)
          ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(dayOfWeek)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.workoutSchedule).insert(WorkoutScheduleCompanion.insert(
        userId: userId,
        dayOfWeek: dayOfWeek,
        templateId: templateId,
      ));
    } else {
      await (_db.update(_db.workoutSchedule)..where((s) => s.id.equals(existing.id))).write(
        WorkoutScheduleCompanion(templateId: Value(templateId)),
      );
    }
  }

  Stream<List<WorkoutScheduleData>> watchSchedule() {
    final userIdFuture = _getCurrentUserId();
    return Stream.fromFuture(userIdFuture).asyncExpand((userId) {
      return (_db.select(_db.workoutSchedule)
            ..where((s) => s.userId.equals(userId))
            ..orderBy([(s) => OrderingTerm.asc(s.dayOfWeek)]))
          .watch();
    });
  }

  Stream<WorkoutTemplate?> watchScheduledTemplateForDate(DateTime date) {
    final day = date.weekday; // 1..7
    final userIdFuture = _getCurrentUserId();
    return Stream.fromFuture(userIdFuture).asyncExpand((userId) {
      final schedStream = (_db.select(_db.workoutSchedule)
            ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(day))
            ..limit(1))
          .watchSingleOrNull();
      return schedStream.asyncExpand((sched) {
        if (sched == null) {
          return Stream<WorkoutTemplate?>.value(null);
        }
        return (_db.select(_db.workoutTemplates)..where((t) => t.id.equals(sched.templateId))).watchSingle().map((t) => t);
      });
    });
  }

  Future<Map<String, TemplateExercise>> readTemplateTargetsForWorkout(int workoutId) async {
    final workout = await (_db.select(_db.workouts)..where((w) => w.id.equals(workoutId))).getSingleOrNull();
    final templateId = workout?.sourceTemplateId;
    if (templateId == null) return {};
    final list = await (_db.select(_db.templateExercises)
          ..where((te) => te.templateId.equals(templateId)))
        .get();
    return {for (final te in list) te.exerciseName: te};
  }

  Stream<bool> watchIsTodaysScheduledWorkoutCompleted() {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final userIdFuture = _getCurrentUserId();
    return Stream.fromFuture(userIdFuture).asyncExpand((userId) {
      final sched$ = (_db.select(_db.workoutSchedule)
            ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(today.weekday))
            ..limit(1))
          .watchSingleOrNull();
      final finished$ = (_db.select(_db.workouts)
            ..where((w) => w.finishedAt.isNotNull() & w.userId.equals(userId)))
          .watch();
      return sched$.asyncExpand((sched) {
        return finished$.map((list) {
          if (sched == null) return false; // no schedule => not completed
          for (final w in list) {
            final started = w.startedAt;
            final isToday = started.isAfter(today.subtract(const Duration(milliseconds: 1))) && started.isBefore(tomorrow);
            if (!isToday) continue;
            if (w.sourceTemplateId != null && w.sourceTemplateId == sched.templateId) return true;
          }
          return false;
        });
      });
    });
  }

  Future<int?> startWorkoutFromTemplate(int templateId) async {
    final template = await (_db.select(_db.workoutTemplates)..where((t) => t.id.equals(templateId))).getSingleOrNull();
    if (template == null) return null;
    final workoutId = await startWorkout(name: template.name, sourceTemplateId: template.id);
    final te = await (_db.select(_db.templateExercises)
          ..where((e) => e.templateId.equals(template.id))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();
    for (final e in te) {
      await addExerciseToWorkout(workoutId: workoutId, exerciseName: e.exerciseName);
    }
    return workoutId;
  }

  Future<Workout?> _findActiveWorkoutForTemplateToday(int templateId) async {
    final today = _dateOnly(DateTime.now());
    final rows = await _db.customSelect(
      'SELECT * FROM workouts WHERE source_template_id = ?1 AND finished_at IS NULL',
      variables: [Variable<int>(templateId)],
      readsFrom: {_db.workouts},
    ).get();
    if (rows.isEmpty) return null;
    for (final r in rows) {
      final w = _db.workouts.map(r.data);
      final started = _dateOnly(w.startedAt);
      if (started == today) return w;
    }
    return null;
  }

  Future<int?> startOrResumeTodaysScheduledWorkout() async {
    final now = DateTime.now();
    final day = now.weekday;
    final userId = await _getCurrentUserId();
    final sched = await (_db.select(_db.workoutSchedule)
          ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(day))
          ..limit(1))
        .getSingleOrNull();
    if (sched == null) return null;
    final active = await _findActiveWorkoutForTemplateToday(sched.templateId);
    if (active != null) return active.id;
    return startWorkoutFromTemplate(sched.templateId);
  }

  Future<int> restartWorkoutFrom(int oldWorkoutId) async {
    final old = await (_db.select(_db.workouts)..where((w) => w.id.equals(oldWorkoutId))).getSingle();
    final newWorkoutId = await startWorkout(name: old.name, sourceTemplateId: old.sourceTemplateId);
    final oldExercises = await (_db.select(_db.workoutExercises)
          ..where((we) => we.workoutId.equals(oldWorkoutId))
          ..orderBy([(we) => OrderingTerm.asc(we.orderIndex)]))
        .get();
    for (final we in oldExercises) {
      // Find exercise name
      final ex = await (_db.select(_db.exercises)..where((e) => e.id.equals(we.exerciseId))).getSingle();
      final newWeId = await addExerciseToWorkout(workoutId: newWorkoutId, exerciseName: ex.name);
      final oldSets = await (_db.select(_db.workoutSets)
            ..where((ws) => ws.workoutExerciseId.equals(we.id))
            ..orderBy([(ws) => OrderingTerm.asc(ws.setIndex)]))
          .get();
      for (final s in oldSets) {
        await _db.into(_db.workoutSets).insert(WorkoutSetsCompanion.insert(
          workoutExerciseId: newWeId,
          setIndex: Value(s.setIndex),
          weight: Value(s.weight),
          reps: Value(s.reps),
        ));
      }
    }
    return newWorkoutId;
  }

  Future<Workout?> getWorkoutById(int id) async {
    return (_db.select(_db.workouts)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  Stream<Workout?> watchTodaysWorkoutAnyStatus() {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final q = (_db.select(_db.workouts)
      ..where((w) => w.startedAt.isBiggerOrEqualValue(today) & w.startedAt.isSmallerThanValue(tomorrow))
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
      ..limit(1));
    return q.watchSingleOrNull();
  }

  Future<void> reopenWorkout(int workoutId) async {
    await (_db.update(_db.workouts)..where((w) => w.id.equals(workoutId))).write(
      const WorkoutsCompanion(finishedAt: Value(null)),
    );
  }

  Future<int> resetWorkoutFrom(int oldWorkoutId) async {
    final old = await (_db.select(_db.workouts)..where((w) => w.id.equals(oldWorkoutId))).getSingle();
    final newWorkoutId = await startWorkout(name: old.name, sourceTemplateId: old.sourceTemplateId);
    final oldExercises = await (_db.select(_db.workoutExercises)
          ..where((we) => we.workoutId.equals(oldWorkoutId))
          ..orderBy([(we) => OrderingTerm.asc(we.orderIndex)]))
        .get();
    for (final we in oldExercises) {
      final ex = await (_db.select(_db.exercises)..where((e) => e.id.equals(we.exerciseId))).getSingle();
      await addExerciseToWorkout(workoutId: newWorkoutId, exerciseName: ex.name);
    }
    return newWorkoutId;
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

final templatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  return ref.read(workoutRepositoryProvider).watchTemplates();
});

final templateExercisesProvider = StreamProvider.family<List<TemplateExercise>, int>((ref, templateId) {
  return ref.read(workoutRepositoryProvider).watchTemplateExercises(templateId);
});

final scheduledTemplateTodayProvider = StreamProvider<WorkoutTemplate?>((ref) {
  return ref.read(workoutRepositoryProvider).watchScheduledTemplateForDate(DateTime.now());
});

final scheduleProvider = StreamProvider<List<WorkoutScheduleData>>((ref) {
  return ref.read(workoutRepositoryProvider).watchSchedule();
});

final workoutTemplateTargetsProvider = FutureProvider.family<Map<String, TemplateExercise>, int>((ref, workoutId) {
  return ref.read(workoutRepositoryProvider).readTemplateTargetsForWorkout(workoutId);
});

final todaysScheduledWorkoutCompletedProvider = StreamProvider<bool>((ref) {
  return ref.read(workoutRepositoryProvider).watchIsTodaysScheduledWorkoutCompleted();
});

final todaysWorkoutAnyProvider = StreamProvider<Workout?>((ref) {
  return ref.read(workoutRepositoryProvider).watchTodaysWorkoutAnyStatus();
});
