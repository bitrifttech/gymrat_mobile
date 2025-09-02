import 'dart:math';
import 'package:app/data/db/app_database.dart';
import 'package:drift/drift.dart';

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

Future<void> seedDemoData(AppDatabase db) async {
  final seeded = await db.readSetting('demoSeeded');
  if (seeded == 'true') return;
  final hasUser = await db.hasAnyUser();
  if (hasUser) return;

  // Create user and goals
  final userId = await db.into(db.users).insert(UsersCompanion.insert(
        ageYears: const Value(30),
        heightCm: const Value(178),
        weightKg: const Value(80.0),
        gender: const Value('Male'),
        activityLevel: const Value('moderate'),
      ));
  await db.into(db.goals).insert(GoalsCompanion.insert(
        userId: userId,
        caloriesMin: 2200,
        caloriesMax: 2500,
        proteinG: 180,
        carbsG: 250,
        fatsG: 70,
      ));

  // Foods catalog
  final foodIds = <String, int>{};
  Future<void> addFood(String key, String name, int kcal, int p, int c, int f) async {
    final id = await db.into(db.foods).insert(FoodsCompanion.insert(
          userId: userId,
          name: name,
          calories: Value(kcal),
          proteinG: Value(p),
          carbsG: Value(c),
          fatsG: Value(f),
          isCustom: const Value(true),
          source: const Value('custom'),
        ));
    foodIds[key] = id;
  }

  await addFood('chicken', 'Chicken Breast (100g)', 165, 31, 0, 4);
  await addFood('rice', 'Cooked Rice (1 cup)', 206, 4, 45, 0);
  await addFood('egg', 'Egg (1 large)', 78, 6, 1, 5);
  await addFood('oats', 'Oatmeal (1/2 cup dry)', 150, 5, 27, 3);
  await addFood('yogurt', 'Greek Yogurt (170g)', 100, 17, 6, 0);
  await addFood('apple', 'Apple (1 medium)', 95, 0, 25, 0);
  await addFood('bread', 'Whole Wheat Bread (1 slice)', 110, 5, 20, 2);
  await addFood('pb', 'Peanut Butter (2 tbsp)', 190, 8, 7, 16);

  // Meals and items for last 14 days
  final rand = Random(42);
  final mealTypes = ['breakfast', 'lunch', 'dinner'];
  for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
    final date = _dateOnly(DateTime.now().subtract(Duration(days: dayOffset)));
    for (final mealType in mealTypes) {
      final mealId = await db.into(db.meals).insert(MealsCompanion.insert(
            userId: userId,
            date: date,
            mealType: mealType,
          ));
      // 2-3 items per meal
      final items = [
        'oats', 'egg', 'yogurt', // breakfast pool
        'chicken', 'rice', 'apple', 'bread', 'pb', // lunch/dinner pool
      ];
      final count = 2 + rand.nextInt(2);
      for (int i = 0; i < count; i++) {
        final key = items[rand.nextInt(items.length)];
        final foodId = foodIds[key]!;
        // quantity between 1.0 and 1.8
        final qty = 1.0 + rand.nextInt(9) / 10.0;
        final food = await (db.select(db.foods)..where((f) => f.id.equals(foodId))).getSingle();
        final calories = (food.calories * qty).round();
        final p = (food.proteinG * qty).round();
        final c = (food.carbsG * qty).round();
        final f = (food.fatsG * qty).round();
        await db.into(db.mealItems).insert(MealItemsCompanion.insert(
              mealId: mealId,
              foodId: foodId,
              quantity: Value(qty),
              calories: Value(calories),
              proteinG: Value(p),
              carbsG: Value(c),
              fatsG: Value(f),
            ));
      }
    }
  }

  // Exercises
  Future<int> ensureExercise(String name) async {
    final existing = await (db.select(db.exercises)
          ..where((e) => e.userId.equals(userId) & e.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return db.into(db.exercises).insert(ExercisesCompanion.insert(userId: userId, name: name));
  }

  final squatId = await ensureExercise('Back Squat');
  final benchId = await ensureExercise('Bench Press');
  final deadId = await ensureExercise('Deadlift');
  final rowId = await ensureExercise('Barbell Row');

  // 8 workouts over last 21 days
  final workoutDays = <int>{0, 2, 4, 6, 8, 11, 14, 18};
  for (final d in workoutDays) {
    final startedAt = DateTime.now().subtract(Duration(days: d, hours: rand.nextInt(3) + 17));
    final wid = await db.into(db.workouts).insert(WorkoutsCompanion.insert(
          userId: userId,
          name: Value('Session ${_dateOnly(startedAt).month}/${_dateOnly(startedAt).day}'),
          startedAt: Value(startedAt),
          finishedAt: Value(startedAt.add(Duration(minutes: 45 + rand.nextInt(20)))),
        ));

    Future<int> addWe(int exerciseId, int orderIdx) async {
      return db.into(db.workoutExercises).insert(WorkoutExercisesCompanion.insert(
            workoutId: wid,
            exerciseId: exerciseId,
            orderIndex: Value(orderIdx),
          ));
    }

    final weSquat = await addWe(squatId, 0);
    final weBench = await addWe(benchId, 1);
    final weRow = await addWe(rowId, 2);

    Future<void> addSets(int weId, double baseWeight) async {
      for (int s = 1; s <= 3 + rand.nextInt(2); s++) {
        final weight = baseWeight + rand.nextInt(6) * 2.5;
        final reps = 5 + rand.nextInt(4);
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              workoutExerciseId: weId,
              setIndex: Value(s),
              weight: Value(weight),
              reps: Value(reps),
            ));
      }
    }

    await addSets(weSquat, 80.0 + rand.nextInt(20).toDouble());
    await addSets(weBench, 60.0 + rand.nextInt(15).toDouble());
    await addSets(weRow, 55.0 + rand.nextInt(15).toDouble());

    if (rand.nextBool()) {
      final weDead = await addWe(deadId, 3);
      await addSets(weDead, 100.0 + rand.nextInt(30).toDouble());
    }
  }

  await db.upsertSetting('demoSeeded', 'true');
}
