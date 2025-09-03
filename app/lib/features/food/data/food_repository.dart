import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';
import 'package:dio/dio.dart';

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

class DailyMacroTotals {
  const DailyMacroTotals({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });
  final DateTime date;
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
  FoodRepository(this._db) : _dio = Dio(BaseOptions(baseUrl: 'https://world.openfoodfacts.org')); 
  final AppDatabase _db;
  final Dio _dio;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<int> _getCurrentUserId() async {
    final u = await (_db.select(_db.users)
          ..orderBy([(u) => OrderingTerm.desc(u.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (u == null) {
      throw StateError('No user found. Complete onboarding.');
    }
    return u.id;
  }

  Future<Food?> getFoodById(int id) async {
    return (_db.select(_db.foods)..where((f) => f.id.equals(id))).getSingleOrNull();
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
      isCustom: const Value(true),
      source: const Value('custom'),
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

  Stream<MacroTotals> watchTotalsForDate(DateTime date) {
    final day = _dateOnly(date);
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

  Future<void> updateItemQuantity({required int itemId, required double quantity}) async {
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

  // Nutrition history (7/30 days)
  Future<List<DailyMacroTotals>> readDailyMacroTotals({required int days}) async {
    final today = _dateOnly(DateTime.now());
    final since = today.subtract(Duration(days: days - 1));
    final rows = await _db.customSelect(
      'SELECT m.date AS d, '
      '       COALESCE(SUM(mi.calories), 0) AS calories, '
      '       COALESCE(SUM(mi.protein_g), 0) AS proteinG, '
      '       COALESCE(SUM(mi.carbs_g), 0) AS carbsG, '
      '       COALESCE(SUM(mi.fats_g), 0) AS fatsG '
      'FROM meals m '
      'LEFT JOIN meal_items mi ON mi.meal_id = m.id '
      'WHERE m.date BETWEEN ?1 AND ?2 '
      'GROUP BY m.date '
      'ORDER BY m.date ASC',
      variables: [Variable<DateTime>(since), Variable<DateTime>(today)],
      readsFrom: {_db.meals, _db.mealItems},
    ).get();

    DateTime _toDate(Object? v) {
      if (v is DateTime) return _dateOnly(v);
      if (v is int) return _dateOnly(DateTime.fromMillisecondsSinceEpoch(v));
      if (v is String) {
        try { return _dateOnly(DateTime.parse(v)); } catch (_) {}
      }
      return today;
    }

    final map = {for (final r in rows) _toDate(r.data['d']): r};
    final result = <DailyMacroTotals>[];
    for (int i = 0; i < days; i++) {
      final d = since.add(Duration(days: i));
      final row = map[d];
      result.add(DailyMacroTotals(
        date: d,
        calories: row == null ? 0 : (row.data['calories'] as int? ?? 0),
        proteinG: row == null ? 0 : (row.data['proteinG'] as int? ?? 0),
        carbsG: row == null ? 0 : (row.data['carbsG'] as int? ?? 0),
        fatsG: row == null ? 0 : (row.data['fatsG'] as int? ?? 0),
      ));
    }
    return result;
  }

  Future<DateTime?> readEarliestMealDate() async {
    final row = await _db.customSelect(
      'SELECT MIN(date) AS d FROM meals',
      readsFrom: {_db.meals},
    ).getSingleOrNull();
    if (row == null) return null;
    final v = row.data['d'];
    if (v == null) return null;
    if (v is DateTime) return _dateOnly(v);
    if (v is int) return _dateOnly(DateTime.fromMillisecondsSinceEpoch(v));
    if (v is String) {
      try { return _dateOnly(DateTime.parse(v)); } catch (_) { return null; }
    }
    return null;
  }

  Future<List<DailyMacroTotals>> readDailyMacrosInRange({required DateTime start, required DateTime end}) async {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final rows = await _db.customSelect(
      'SELECT m.date AS d, '
      '       COALESCE(SUM(mi.calories), 0) AS calories, '
      '       COALESCE(SUM(mi.protein_g), 0) AS proteinG, '
      '       COALESCE(SUM(mi.carbs_g), 0) AS carbsG, '
      '       COALESCE(SUM(mi.fats_g), 0) AS fatsG '
      'FROM meals m '
      'JOIN meal_items mi ON mi.meal_id = m.id '
      'WHERE m.date >= ?1 AND m.date <= ?2 '
      'GROUP BY m.date '
      'ORDER BY m.date ASC',
      variables: [Variable<DateTime>(s), Variable<DateTime>(e)],
      readsFrom: {_db.meals, _db.mealItems},
    ).get();
    DateTime _toDate(Object? v) {
      if (v is DateTime) return _dateOnly(v);
      if (v is int) return _dateOnly(DateTime.fromMillisecondsSinceEpoch(v));
      if (v is String) { try { return _dateOnly(DateTime.parse(v)); } catch (_) {} }
      return _dateOnly(DateTime.now());
    }
    final map = {for (final r in rows) _toDate(r.data['d']): r};
    final result = <DailyMacroTotals>[];
    for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      final row = map[d];
      result.add(DailyMacroTotals(
        date: d,
        calories: row == null ? 0 : (row.data['calories'] as int? ?? 0),
        proteinG: row == null ? 0 : (row.data['proteinG'] as int? ?? 0),
        carbsG: row == null ? 0 : (row.data['carbsG'] as int? ?? 0),
        fatsG: row == null ? 0 : (row.data['fatsG'] as int? ?? 0),
      ));
    }
    return result;
  }

  // Fallback: Build daily totals by querying each day individually (same logic as Meal History)
  Future<List<DailyMacroTotals>> readDailyMacrosByDays({required DateTime start, required DateTime end}) async {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final result = <DailyMacroTotals>[];
    for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
      final row = await _db.customSelect(
        'SELECT '
        'COALESCE(SUM(mi.calories), 0) AS calories, '
        'COALESCE(SUM(mi.protein_g), 0) AS proteinG, '
        'COALESCE(SUM(mi.carbs_g), 0) AS carbsG, '
        'COALESCE(SUM(mi.fats_g), 0) AS fatsG '
        'FROM meal_items mi '
        'JOIN meals m ON m.id = mi.meal_id '
        'WHERE m.date = ?1',
        variables: [Variable<DateTime>(d)],
        readsFrom: {_db.mealItems, _db.meals},
      ).getSingle();
      result.add(DailyMacroTotals(
        date: d,
        calories: (row.data['calories'] as int?) ?? 0,
        proteinG: (row.data['proteinG'] as int?) ?? 0,
        carbsG: (row.data['carbsG'] as int?) ?? 0,
        fatsG: (row.data['fatsG'] as int?) ?? 0,
      ));
    }
    return result;
  }

  // --- Open Food Facts integration ---

  Future<int> _cacheOrUpdateOFFFood(Map<String, dynamic> p) async {
    final userId = await _getCurrentUserId();
    final barcode = p['code'] as String?;
    final product = p['product'] as Map<String, dynamic>?;
    if (product == null) throw StateError('Invalid product payload');

    String name = (product['product_name'] as String?)?.trim() ?? 'Unknown';
    String? brand = (product['brands'] as String?)?.split(',').first.trim();
    String? servingDesc = (product['serving_size'] as String?)?.trim();
    double? servingQty;
    String? servingUnit;
    if (servingDesc != null) {
      final parts = servingDesc.split(' ');
      if (parts.length >= 2) {
        servingQty = double.tryParse(parts[0]);
        servingUnit = parts[1];
      }
    }

    int kcal = (product['nutriments']?['energy-kcal_100g'] as num?)?.round() ?? (product['nutriments']?['energy-kcal_serving'] as num?)?.round() ?? 0;
    int protein = (product['nutriments']?['proteins_100g'] as num?)?.round() ?? (product['nutriments']?['proteins_serving'] as num?)?.round() ?? 0;
    int carbs = (product['nutriments']?['carbohydrates_100g'] as num?)?.round() ?? (product['nutriments']?['carbohydrates_serving'] as num?)?.round() ?? 0;
    int fats = (product['nutriments']?['fat_100g'] as num?)?.round() ?? (product['nutriments']?['fat_serving'] as num?)?.round() ?? 0;

    final existing = barcode != null
        ? await (_db.select(_db.foods)..where((f) => f.barcode.equals(barcode))).getSingleOrNull()
        : null;
    final companion = FoodsCompanion(
      userId: Value(userId),
      name: Value(name),
      brand: Value(brand),
      servingDesc: Value(servingDesc),
      barcode: Value(barcode),
      source: const Value('off'),
      remoteId: Value(barcode),
      isCustom: const Value(false),
      servingQty: Value(servingQty),
      servingUnit: Value(servingUnit),
      calories: Value(kcal),
      proteinG: Value(protein),
      carbsG: Value(carbs),
      fatsG: Value(fats),
    );
    if (existing == null) {
      return _db.into(_db.foods).insert(companion);
    } else {
      await (_db.update(_db.foods)..where((f) => f.id.equals(existing.id))).write(companion);
      return existing.id;
    }
  }

  Future<int?> fetchByBarcodeAndCache(String barcode) async {
    try {
      final res = await _dio.get('/api/v2/product/$barcode.json');
      final data = res.data is String ? jsonDecode(res.data as String) : res.data as Map<String, dynamic>;
      if (data['status'] == 1) {
        return _cacheOrUpdateOFFFood({'code': barcode, 'product': data['product'] as Map<String, dynamic>});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> searchFoodsAndCache(String query, {int page = 1, int pageSize = 10}) async {
    try {
      final res = await _dio.get('/cgi/search.pl', queryParameters: {
        'search_terms': query,
        'search_simple': 1,
        'json': 1,
        'page': page,
        'page_size': pageSize,
      });
      final data = res.data is String ? jsonDecode(res.data as String) : res.data as Map<String, dynamic>;
      final products = (data['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final ids = <int>[];
      for (final p in products) {
        final id = await _cacheOrUpdateOFFFood({'code': p['code'], 'product': p});
        ids.add(id);
      }
      return ids;
    } catch (_) {
      return [];
    }
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

final offSearchResultsProvider = FutureProvider.autoDispose.family<List<Food>, String>((ref, query) async {
  final repo = ref.read(foodRepositoryProvider);
  if (query.isEmpty) return [];
  final ids = await repo.searchFoodsAndCache(query);
  if (ids.isEmpty) return [];
  final foodsList = await (repo._db.select(repo._db.foods)..where((f) => f.id.isIn(ids))).get();
  return foodsList;
});

final dailyMacros7Provider = FutureProvider<List<DailyMacroTotals>>((ref) async {
  return ref.read(foodRepositoryProvider).readDailyMacroTotals(days: 7);
});

final dailyMacros30Provider = FutureProvider<List<DailyMacroTotals>>((ref) async {
  return ref.read(foodRepositoryProvider).readDailyMacroTotals(days: 30);
});

final mealsForDateProvider = StreamProvider.family<List<(Meal, List<(MealItem, Food)>)>, DateTime>((ref, date) {
  return ref.read(foodRepositoryProvider).watchMealsForDay(date);
});

final totalsForDateProvider = StreamProvider.family<MacroTotals, DateTime>((ref, date) {
  return ref.read(foodRepositoryProvider).watchTotalsForDate(date);
});
