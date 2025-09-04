import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class WeeklyVolume {
  const WeeklyVolume({required this.yearWeek, required this.tonnage});
  final String yearWeek; // e.g., 2025-03
  final double tonnage;
}

class ExerciseVolume {
  const ExerciseVolume({required this.exerciseName, required this.tonnage});
  final String exerciseName;
  final double tonnage;
}

class BestOneRm {
  const BestOneRm({required this.exerciseName, required this.oneRm});
  final String exerciseName;
  final double oneRm;
}

class WorkoutExerciseSummary {
  const WorkoutExerciseSummary({required this.exerciseName, required this.setsCount, required this.tonnage});
  final String exerciseName;
  final int setsCount;
  final double tonnage;
}

class WorkoutSummaryData {
  const WorkoutSummaryData({
    required this.workout,
    required this.totalSets,
    required this.totalTonnage,
    required this.exercises,
  });
  final Workout workout;
  final int totalSets;
  final double totalTonnage;
  final List<WorkoutExerciseSummary> exercises;
}

class RecentPr {
  const RecentPr({required this.exerciseName, required this.oneRm, required this.date});
  final String exerciseName;
  final double oneRm;
  final DateTime date;
}

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

  Future<void> renameTemplate({required int templateId, required String name}) async {
    await (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(templateId))).write(
      WorkoutTemplatesCompanion(name: Value(name)),
    );
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

  Future<void> renameTemplateExercise({required int templateExerciseId, required String name}) async {
    await (_db.update(_db.templateExercises)..where((te) => te.id.equals(templateExerciseId))).write(
      TemplateExercisesCompanion(exerciseName: Value(name)),
    );
  }

  Future<void> deleteTemplateExercise(int templateExerciseId) async {
    await (_db.delete(_db.templateExercises)..where((te) => te.id.equals(templateExerciseId))).go();
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

  Future<void> clearScheduleForDay(int dayOfWeek) async {
    final userId = await _getCurrentUserId();
    await (_db.delete(_db.workoutSchedule)
          ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(dayOfWeek)))
        .go();
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

  Future<void> deleteWorkout(int workoutId) async {
    await _db.transaction(() async {
      // Delete sets for all workout_exercises under this workout
      final weIds = await (_db.select(_db.workoutExercises)
            ..where((we) => we.workoutId.equals(workoutId)))
          .get()
          .then((list) => list.map((e) => e.id).toList());
      if (weIds.isNotEmpty) {
        await (_db.delete(_db.workoutSets)
              ..where((ws) => ws.workoutExerciseId.isIn(weIds)))
            .go();
      }
      await (_db.delete(_db.workoutExercises)..where((we) => we.workoutId.equals(workoutId))).go();
      await (_db.delete(_db.workouts)..where((w) => w.id.equals(workoutId))).go();
    });
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

  Stream<Workout?> watchTodaysScheduledWorkoutAnyStatus() {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final userIdFuture = _getCurrentUserId();
    return Stream.fromFuture(userIdFuture).asyncExpand((userId) {
      final sched$ = (_db.select(_db.workoutSchedule)
            ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(today.weekday))
            ..limit(1))
          .watchSingleOrNull();
      return sched$.asyncExpand((sched) {
        if (sched == null) return Stream<Workout?>.value(null);
        final q = (_db.select(_db.workouts)
          ..where((w) => w.sourceTemplateId.equals(sched.templateId) & w.startedAt.isBiggerOrEqualValue(today) & w.startedAt.isSmallerThanValue(tomorrow))
          ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
          ..limit(1));
        return q.watchSingleOrNull();
      });
    });
  }

  Future<void> deleteTodaysScheduledWorkouts() async {
    final userId = await _getCurrentUserId();
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final sched = await (_db.select(_db.workoutSchedule)
          ..where((s) => s.userId.equals(userId) & s.dayOfWeek.equals(today.weekday))
          ..limit(1))
        .getSingleOrNull();
    if (sched == null) return;
    final list = await (_db.select(_db.workouts)
          ..where((w) => w.sourceTemplateId.equals(sched.templateId) & w.startedAt.isBiggerOrEqualValue(today) & w.startedAt.isSmallerThanValue(tomorrow)))
        .get();
    for (final w in list) {
      await deleteWorkout(w.id);
    }
  }

  // ----- Metrics: Workouts -----

  Future<List<WeeklyVolume>> readWeeklyVolume({int weeks = 6}) async {
    final userId = await _getCurrentUserId();
    final since = DateTime.now().subtract(Duration(days: weeks * 7));
    final rows = await _db.customSelect(
      "SELECT strftime('%Y-%W', w.started_at) AS yw, "
      "       COALESCE(SUM(COALESCE(ws.weight,0.0) * COALESCE(ws.reps,0)), 0) AS tonnage "
      'FROM workout_sets ws '
      'JOIN workout_exercises we ON we.id = ws.workout_exercise_id '
      'JOIN workouts w ON w.id = we.workout_id '
      'WHERE w.user_id = ?1 AND w.finished_at IS NOT NULL AND w.started_at >= ?2 '
      'GROUP BY yw '
      'ORDER BY yw ASC',
      variables: [Variable<int>(userId), Variable<DateTime>(since)],
      readsFrom: {_db.workoutSets, _db.workoutExercises, _db.workouts},
    ).get();
    return rows
        .map((r) => WeeklyVolume(
              yearWeek: (r.data['yw'] as String?) ?? '',
              tonnage: ((r.data['tonnage'] as num?) ?? 0).toDouble(),
            ))
        .toList();
  }

  Future<List<ExerciseVolume>> readTopExerciseVolume({int weeks = 6, int topN = 5}) async {
    final userId = await _getCurrentUserId();
    final since = DateTime.now().subtract(Duration(days: weeks * 7));
    final rows = await _db.customSelect(
      'SELECT e.name AS name, '
      "       COALESCE(SUM(COALESCE(ws.weight,0.0) * COALESCE(ws.reps,0)), 0) AS tonnage "
      'FROM workout_sets ws '
      'JOIN workout_exercises we ON ws.workout_exercise_id = we.id '
      'JOIN workouts w ON w.id = we.workout_id '
      'JOIN exercises e ON e.id = we.exercise_id '
      'WHERE w.user_id = ?1 AND w.finished_at IS NOT NULL AND w.started_at >= ?2 '
      'GROUP BY e.name '
      'ORDER BY tonnage DESC '
      'LIMIT ?3',
      variables: [Variable<int>(userId), Variable<DateTime>(since), Variable<int>(topN)],
      readsFrom: {_db.workoutSets, _db.workoutExercises, _db.workouts, _db.exercises},
    ).get();
    return rows
        .map((r) => ExerciseVolume(
              exerciseName: (r.data['name'] as String?) ?? 'Exercise',
              tonnage: ((r.data['tonnage'] as num?) ?? 0).toDouble(),
            ))
        .toList();
  }

  Future<List<BestOneRm>> readBestOneRm({int topN = 5}) async {
    final userId = await _getCurrentUserId();
    final rows = await _db.customSelect(
      'SELECT e.name AS name, '
      "       MAX(COALESCE(ws.weight,0.0) * (1.0 + COALESCE(ws.reps,0)/30.0)) AS oneRm "
      'FROM workout_sets ws '
      'JOIN workout_exercises we ON ws.workout_exercise_id = we.id '
      'JOIN workouts w ON w.id = we.workout_id '
      'JOIN exercises e ON e.id = we.exercise_id '
      'WHERE w.user_id = ?1 AND w.finished_at IS NOT NULL '
      'GROUP BY e.name '
      'ORDER BY oneRm DESC '
      'LIMIT ?2',
      variables: [Variable<int>(userId), Variable<int>(topN)],
      readsFrom: {_db.workoutSets, _db.workoutExercises, _db.workouts, _db.exercises},
    ).get();
    return rows
        .map((r) => BestOneRm(
              exerciseName: (r.data['name'] as String?) ?? 'Exercise',
              oneRm: ((r.data['oneRm'] as num?) ?? 0).toDouble(),
            ))
        .toList();
  }

  Future<WorkoutSummaryData?> readWorkoutSummary(int workoutId) async {
    final workout = await (_db.select(_db.workouts)..where((w) => w.id.equals(workoutId))).getSingleOrNull();
    if (workout == null) return null;
    final rows = await _db.customSelect(
      'SELECT e.name AS name, COUNT(ws.id) AS setsCount, '
      "COALESCE(SUM(COALESCE(ws.weight,0.0) * COALESCE(ws.reps,0)), 0) AS tonnage "
      'FROM workout_exercises we '
      'JOIN exercises e ON e.id = we.exercise_id '
      'LEFT JOIN workout_sets ws ON ws.workout_exercise_id = we.id '
      'WHERE we.workout_id = ?1 '
      'GROUP BY e.name '
      'ORDER BY e.name ASC',
      variables: [Variable<int>(workoutId)],
      readsFrom: {_db.workoutExercises, _db.workoutSets, _db.exercises},
    ).get();
    int totalSets = 0;
    double totalTonnage = 0;
    final list = <WorkoutExerciseSummary>[];
    for (final r in rows) {
      final setsCount = (r.data['setsCount'] as int?) ?? 0;
      final tonnage = ((r.data['tonnage'] as num?) ?? 0).toDouble();
      totalSets += setsCount;
      totalTonnage += tonnage;
      list.add(WorkoutExerciseSummary(
        exerciseName: (r.data['name'] as String?) ?? 'Exercise',
        setsCount: setsCount,
        tonnage: tonnage,
      ));
    }
    return WorkoutSummaryData(workout: workout, totalSets: totalSets, totalTonnage: totalTonnage, exercises: list);
  }

  Future<List<RecentPr>> readRecentPrs({int days = 7}) async {
    final userId = await _getCurrentUserId();
    final since = DateTime.now().subtract(Duration(days: days));
    // Global best per exercise
    final best = await readBestOneRm(topN: 1000);
    final bestMap = {for (final b in best) b.exerciseName: b.oneRm};
    // Sets in window with exercise names and workout dates
    final rows = await _db.customSelect(
      'SELECT e.name AS name, w.started_at AS startedAt, '
      "       (COALESCE(ws.weight,0.0) * (1.0 + COALESCE(ws.reps,0)/30.0)) AS oneRm "
      'FROM workout_sets ws '
      'JOIN workout_exercises we ON ws.workout_exercise_id = we.id '
      'JOIN workouts w ON w.id = we.workout_id '
      'JOIN exercises e ON e.id = we.exercise_id '
      'WHERE w.user_id = ?1 AND w.finished_at IS NOT NULL AND w.started_at >= ?2',
      variables: [Variable<int>(userId), Variable<DateTime>(since)],
      readsFrom: {_db.workoutSets, _db.workoutExercises, _db.workouts, _db.exercises},
    ).get();
    final byExercise = <String, RecentPr?>{};
    for (final r in rows) {
      final name = (r.data['name'] as String?) ?? '';
      final raw = r.data['startedAt'];
      DateTime startedAt;
      if (raw is DateTime) {
        startedAt = raw;
      } else if (raw is int) {
        startedAt = DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is String) {
        try {
          startedAt = DateTime.parse(raw);
        } catch (_) {
          startedAt = DateTime.now();
        }
      } else {
        startedAt = DateTime.now();
      }
      final oneRm = ((r.data['oneRm'] as num?) ?? 0).toDouble();
      final bestVal = bestMap[name] ?? 0;
      if (oneRm > 0 && (oneRm >= bestVal - 0.0001)) {
        final current = byExercise[name];
        if (current == null || startedAt.isAfter(current.date)) {
          byExercise[name] = RecentPr(exerciseName: name, oneRm: oneRm, date: startedAt);
        }
      }
    }
    return byExercise.values.whereType<RecentPr>().toList()..sort((a, b) => b.date.compareTo(a.date));
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

final todaysScheduledWorkoutAnyProvider = StreamProvider<Workout?>((ref) {
  return ref.read(workoutRepositoryProvider).watchTodaysScheduledWorkoutAnyStatus();
});

final weeklyVolumeProvider = FutureProvider<List<WeeklyVolume>>((ref) async {
  return ref.read(workoutRepositoryProvider).readWeeklyVolume(weeks: 6);
});

final topExerciseVolumeProvider = FutureProvider<List<ExerciseVolume>>((ref) async {
  return ref.read(workoutRepositoryProvider).readTopExerciseVolume(weeks: 6, topN: 5);
});

final bestOneRmProvider = FutureProvider<List<BestOneRm>>((ref) async {
  return ref.read(workoutRepositoryProvider).readBestOneRm(topN: 5);
});

final workoutSummaryProvider = FutureProvider.family<WorkoutSummaryData?, int>((ref, workoutId) async {
  return ref.read(workoutRepositoryProvider).readWorkoutSummary(workoutId);
});

final recentPrsProvider = FutureProvider<List<RecentPr>>((ref) async {
  return ref.read(workoutRepositoryProvider).readRecentPrs(days: 7);
});
