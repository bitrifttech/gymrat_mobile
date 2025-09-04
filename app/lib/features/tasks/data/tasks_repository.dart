import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class TasksRepository {
  TasksRepository(this._db);
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

  // CRUD
  Future<int> createTask({required String title, String? notes}) async {
    final userId = await _getCurrentUserId();
    return _db.into(_db.tasks).insert(TasksCompanion.insert(
          userId: userId,
          title: title,
          notes: Value(notes),
        ));
  }

  Future<void> updateTask({required int taskId, String? title, String? notes}) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(TasksCompanion(
      title: title == null ? const Value.absent() : Value(title),
      notes: notes == null ? const Value.absent() : Value(notes),
    ));
  }

  Future<void> deleteTask(int taskId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskSchedule)..where((ts) => ts.taskId.equals(taskId))).go();
      await (_db.delete(_db.taskLog)..where((tl) => tl.taskId.equals(taskId))).go();
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
    });
  }

  // Schedule
  Future<void> assignTaskToDay({required int taskId, required int dayOfWeek}) async {
    final userId = await _getCurrentUserId();
    final existing = await (_db.select(_db.taskSchedule)
          ..where((ts) => ts.userId.equals(userId) & ts.taskId.equals(taskId) & ts.dayOfWeek.equals(dayOfWeek)))
        .getSingleOrNull();
    if (existing != null) return;
    await _db.into(_db.taskSchedule).insert(TaskScheduleCompanion.insert(
          userId: userId,
          taskId: taskId,
          dayOfWeek: dayOfWeek,
        ));
  }

  Future<void> unassignTaskFromDay({required int taskId, required int dayOfWeek}) async {
    final userId = await _getCurrentUserId();
    await (_db.delete(_db.taskSchedule)
          ..where((ts) => ts.userId.equals(userId) & ts.taskId.equals(taskId) & ts.dayOfWeek.equals(dayOfWeek)))
        .go();
  }

  Future<void> clearDay(int dayOfWeek) async {
    final userId = await _getCurrentUserId();
    await (_db.delete(_db.taskSchedule)..where((ts) => ts.userId.equals(userId) & ts.dayOfWeek.equals(dayOfWeek))).go();
  }

  Future<List<Task>> readTasksForDay(int dayOfWeek) async {
    final sched = await (_db.select(_db.taskSchedule)..where((ts) => ts.dayOfWeek.equals(dayOfWeek))).get();
    if (sched.isEmpty) return [];
    final ids = sched.map((s) => s.taskId).toList();
    return (_db.select(_db.tasks)..where((t) => t.id.isIn(ids))).get();
  }

  // Queries
  Stream<List<Task>> watchAllTasks() {
    return (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  Stream<List<Task>> watchTasksForDay(int dayOfWeek) {
    return (_db.select(_db.taskSchedule)..where((ts) => ts.dayOfWeek.equals(dayOfWeek)))
        .watch()
        .asyncMap((sched) async {
      if (sched.isEmpty) return <Task>[];
      final ids = sched.map((s) => s.taskId).toList();
      final list = await (_db.select(_db.tasks)..where((t) => t.id.isIn(ids))).get();
      // Maintain creation order for now
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Stream<List<Task>> watchTasksForToday() {
    final today = DateTime.now().weekday; // 1..7
    return watchTasksForDay(today);
  }

  // Completion
  Future<void> markTaskDoneForDate({required int taskId, required DateTime date}) async {
    final userId = await _getCurrentUserId();
    final d = _dateOnly(date);
    final existing = await (_db.select(_db.taskLog)
          ..where((tl) => tl.userId.equals(userId) & tl.taskId.equals(taskId) & tl.date.equals(d)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.taskLog).insert(TaskLogCompanion.insert(
            userId: userId,
            taskId: taskId,
            date: d,
            completedAt: Value(DateTime.now()),
          ));
    } else {
      await (_db.update(_db.taskLog)
            ..where((tl) => tl.id.equals(existing.id)))
          .write(TaskLogCompanion(completedAt: Value(DateTime.now())));
    }
  }

  Future<void> unmarkTaskDoneForDate({required int taskId, required DateTime date}) async {
    final userId = await _getCurrentUserId();
    final d = _dateOnly(date);
    await (_db.delete(_db.taskLog)
          ..where((tl) => tl.userId.equals(userId) & tl.taskId.equals(taskId) & tl.date.equals(d)))
        .go();
  }

  Stream<Set<int>> watchCompletedTaskIdsForDate(DateTime date) {
    final d = _dateOnly(date);
    return (_db.select(_db.taskLog)..where((tl) => tl.date.equals(d) & tl.completedAt.isNotNull()))
        .watch()
        .map((rows) => rows.map((r) => r.taskId).toSet());
  }

  // Assignments map: taskId -> set of days
  Stream<Map<int, Set<int>>> watchTaskAssignments() {
    return (_db.select(_db.taskSchedule)).watch().map((rows) {
      final map = <int, Set<int>>{};
      for (final r in rows) {
        map.putIfAbsent(r.taskId, () => <int>{}).add(r.dayOfWeek);
      }
      return map;
    });
  }
}

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return TasksRepository(db);
});

final allTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.read(tasksRepositoryProvider).watchAllTasks();
});

final tasksForDayProvider = StreamProvider.family<List<Task>, int>((ref, day) {
  return ref.read(tasksRepositoryProvider).watchTasksForDay(day);
});

final tasksForTodayProvider = StreamProvider<List<Task>>((ref) {
  return ref.read(tasksRepositoryProvider).watchTasksForToday();
});

final taskAssignmentsProvider = StreamProvider<Map<int, Set<int>>>((ref) {
  return ref.read(tasksRepositoryProvider).watchTaskAssignments();
});

final completedTodayProvider = StreamProvider<Set<int>>((ref) {
  return ref.read(tasksRepositoryProvider).watchCompletedTaskIdsForDate(DateTime.now());
});


