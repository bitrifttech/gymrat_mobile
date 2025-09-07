import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';
import 'package:drift/drift.dart';

class HomeRepository {
  HomeRepository(this._db);
  final AppDatabase _db;

  Future<Goal?> readLatestGoal() async {
    final query = (_db.select(_db.goals)
      ..orderBy([(g) => OrderingTerm.desc(g.createdAt)])
      ..limit(1));
    return query.getSingleOrNull();
  }

  Stream<Goal?> watchLatestGoal() {
    final query = (_db.select(_db.goals)
      ..orderBy([(g) => OrderingTerm.desc(g.createdAt)])
      ..limit(1));
    return query.watchSingleOrNull();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return HomeRepository(db);
});

final latestGoalProvider = StreamProvider<Goal?>((ref) {
  return ref.read(homeRepositoryProvider).watchLatestGoal();
});
