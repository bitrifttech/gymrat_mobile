import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';

class MacroTotals {
  const MacroTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
}

class MealTotals {
  const MealTotals({
    required this.mealType,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final String mealType;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
}

class FoodRepository {
  FoodRepository(this._db);
  final AppDatabase _db;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<int> _getCurrentUserId() async {
    final u = await (_db.select(_db.users)
          ..orderBy([(u) => OrderingTerm.asc(u.id)])
          ..limit(1))
        .getSingleOrNull();
    if (u == null) {
      throw StateError('No user found. Complete onboarding.');
    }
    return u.id;
  }

  Future<int> addCustomFood({
    required String name,
    String? brand,
    String? servingDesc,
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatsG,
  }) async {
    final userId = await _getCurrentUserId();
    return _db.into(_db.foods).insert(FoodsCompanion.insert(
      userId: userId,
      name: name,
      brand: Value(brand),
      servingDesc: Value(servingDesc),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatsG: Value(fatsG),
    ));
  }

  Future<int> _ensureMealFor(DateTime date, String mealType) async {
    final userId = await _getCurrentUserId();
    final day = _dateOnly(date);
    final existing = await (_db.select(_db.meals)
          ..where((m) => m.userId.equals(userId) & m.date.equals(day) & m.mealType.equals(mealType))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.meals).insert(MealsCompanion.insert(
      userId: userId,
      date: day,
      mealType: mealType,
    ));
  }

  Future<void> addExistingFoodToMeal({
    required int foodId,
    required String mealType, // breakfast|lunch|dinner|snack
    double quantity = 1.0,
    String? unit,
  }) async {
    final mealId = await _ensureMealFor(DateTime.now(), mealType);
    await addExistingFoodToSpecificMeal(mealId: mealId, foodId: foodId, quantity: quantity, unit: unit);
  }

  Future<void> addExistingFoodToSpecificMeal({
    required int mealId,
    required int foodId,
    double quantity = 1.0,
    String? unit,
  }) async {
    final food = await (_db.select(_db.foods)..where((f) => f.id.equals(foodId))).getSingle();

    int calories = (food.calories * quantity).round();
    int proteinG = (food.proteinG * quantity).round();
    int carbsG = (food.carbsG * quantity).round();
    int fatsG = (food.fatsG * quantity).round();

    await _db.into(_db.mealItems).insert(MealItemsCompanion.insert(
      mealId: mealId,
      foodId: food.id,
      quantity: Value(quantity),
      unit: Value(unit),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatsG: Value(fatsG),
    ));
  }

  Future<void> addCustomFoodToMeal({
    required String name,
    String? brand,
    String? servingDesc,
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatsG,
    required String mealType,
    double quantity = 1.0,
    String? unit,
  }) async {
    final foodId = await addCustomFood(
      name: name,
      brand: brand,
      servingDesc: servingDesc,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
    );
    await addExistingFoodToMeal(foodId: foodId, mealType: mealType, quantity: quantity, unit: unit);
  }

  Future<List<Food>> listRecentFoodsUsed({int limit = 10}) async {
    final userId = await _getCurrentUserId();
    final rows = await _db.customSelect(
      'SELECT mi.food_id AS foodId, MAX(mi.created_at) AS lastUsed '
      'FROM meal_items mi '
      'JOIN meals m ON m.id = mi.meal_id '
      'WHERE m.user_id = ?1 '
      'GROUP BY mi.food_id '
      'ORDER BY lastUsed DESC '
      'LIMIT ?2',
      variables: [Variable<int>(userId), Variable<int>(limit)],
      readsFrom: {_db.mealItems, _db.meals},
    ).get();

    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r.data['foodId'] as int).toList();
    final foodsList = await (_db.select(_db.foods)..where((f) => f.id.isIn(ids))).get();
    final order = {for (int i = 0; i < ids.length; i++) ids[i]: i};
    foodsList.sort((a, b) => (order[a.id] ?? 0).compareTo(order[b.id] ?? 0));
    return foodsList;
  }

  Stream<MacroTotals> watchTodayTotals() {
    final day = _dateOnly(DateTime.now());
    final query = _db.customSelect(
      'SELECT '
      'COALESCE(SUM(mi.calories), 0) AS calories, '
      'COALESCE(SUM(mi.protein_g), 0) AS proteinG, '
      'COALESCE(SUM(mi.carbs_g), 0) AS carbsG, '
      'COALESCE(SUM(mi.fats_g), 0) AS fatsG '
      'FROM meal_items mi '
      'JOIN meals m ON m.id = mi.meal_id '
      'WHERE m.date = ?1',
      variables: [Variable<DateTime>(day)],
      readsFrom: {_db.mealItems, _db.meals},
    );
    return query.watchSingle().map((row) {
      final data = row.data;
      return MacroTotals(
        calories: (data['calories'] as int?) ?? 0,
        proteinG: (data['proteinG'] as int?) ?? 0,
        carbsG: (data['carbsG'] as int?) ?? 0,
        fatsG: (data['fatsG'] as int?) ?? 0,
      );
    });
  }

  Stream<List<MealTotals>> watchTodayPerMealTotals() {
    final day = _dateOnly(DateTime.now());
    final query = _db.customSelect(
      'SELECT m.meal_type AS mealType, '
      'COALESCE(SUM(mi.calories), 0) AS calories, '
      'COALESCE(SUM(mi.protein_g), 0) AS proteinG, '
      'COALESCE(SUM(mi.carbs_g), 0) AS carbsG, '
      'COALESCE(SUM(mi.fats_g), 0) AS fatsG '
      'FROM meal_items mi '
      'JOIN meals m ON m.id = mi.meal_id '
      'WHERE m.date = ?1 '
      'GROUP BY m.meal_type '
      'ORDER BY m.meal_type',
      variables: [Variable<DateTime>(day)],
      readsFrom: {_db.mealItems, _db.meals},
    );
    return query.watch().map((rows) {
      return rows.map((row) {
        final data = row.data;
        return MealTotals(
          mealType: (data['mealType'] as String?) ?? '',
          calories: (data['calories'] as int?) ?? 0,
          proteinG: (data['proteinG'] as int?) ?? 0,
          carbsG: (data['carbsG'] as int?) ?? 0,
          fatsG: (data['fatsG'] as int?) ?? 0,
        );
      }).toList();
    });
  }

  Stream<List<(Meal, List<(MealItem, Food)>)>> watchMealsForDay(DateTime date) {
    final day = _dateOnly(date);
    // We watch meals for the day and join with items + foods via a manual query per meal for simplicity.
    final mealsStream = (_db.select(_db.meals)..where((m) => m.date.equals(day))).watch();
    return mealsStream.asyncMap((meals) async {
      final result = <(Meal, List<(MealItem, Food)>)>[];
      for (final meal in meals) {
        final items = await (_db.select(_db.mealItems)
              ..where((i) => i.mealId.equals(meal.id)))
            .get();
        final pairs = <(MealItem, Food)>[];
        for (final item in items) {
          final food = await (_db.select(_db.foods)..where((f) => f.id.equals(item.foodId))).getSingle();
          pairs.add((item, food));
        }
        result.add((meal, pairs));
      }
      return result;
    });
  }

  Future<void> updateItemQuantity({required int itemId, required double quantity}) async {
    // Recompute macros proportionally from original food values
    final item = await (_db.select(_db.mealItems)..where((i) => i.id.equals(itemId))).getSingle();
    final food = await (_db.select(_db.foods)..where((f) => f.id.equals(item.foodId))).getSingle();
    final newCalories = (food.calories * quantity).round();
    final newProtein = (food.proteinG * quantity).round();
    final newCarbs = (food.carbsG * quantity).round();
    final newFats = (food.fatsG * quantity).round();
    await (_db.update(_db.mealItems)..where((i) => i.id.equals(itemId))).write(MealItemsCompanion(
      quantity: Value(quantity),
      calories: Value(newCalories),
      proteinG: Value(newProtein),
      carbsG: Value(newCarbs),
      fatsG: Value(newFats),
    ));
  }

  Future<void> deleteMealItem(int itemId) async {
    await (_db.delete(_db.mealItems)..where((i) => i.id.equals(itemId))).go();
  }
}

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return FoodRepository(db);
});

final todayTotalsProvider = StreamProvider<MacroTotals>((ref) {
  return ref.read(foodRepositoryProvider).watchTodayTotals();
});

final recentFoodsProvider = FutureProvider.autoDispose<List<Food>>((ref) async {
  return ref.read(foodRepositoryProvider).listRecentFoodsUsed(limit: 10);
});

final todayPerMealTotalsProvider = StreamProvider<List<MealTotals>>((ref) {
  return ref.read(foodRepositoryProvider).watchTodayPerMealTotals();
});

final todaysMealsProvider = StreamProvider.autoDispose<List<(Meal, List<(MealItem, Food)>)>>((ref) {
  final repo = ref.read(foodRepositoryProvider);
  return repo.watchMealsForDay(DateTime.now());
});
