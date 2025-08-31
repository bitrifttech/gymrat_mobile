import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/data/db/app_database.dart';
import 'package:drift/drift.dart';

class OnboardingRepository {
  OnboardingRepository(this._db);
  final AppDatabase _db;

  Future<bool> isOnboardingComplete() async {
    final hasUser = await _db.hasAnyUser();
    return hasUser;
  }

  Future<void> completeWithDefaults() async {
    await saveOnboarding(
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      gender: 'Other',
      activityLevel: 'Active',
      caloriesMin: 2000,
      caloriesMax: 2200,
      proteinG: 150,
      carbsG: 250,
      fatsG: 70,
    );
  }

  Future<void> saveOnboarding({
    required int ageYears,
    required int heightCm,
    required double weightKg,
    required String gender,
    required String activityLevel,
    required int caloriesMin,
    required int caloriesMax,
    required int proteinG,
    required int carbsG,
    required int fatsG,
  }) async {
    await _db.transaction(() async {
      final userId = await _db.into(_db.users).insert(UsersCompanion.insert(
        name: const Value.absent(),
        email: const Value.absent(),
        ageYears: Value(ageYears),
        heightCm: Value(heightCm),
        weightKg: Value(weightKg),
        gender: Value(gender),
        activityLevel: Value(activityLevel),
      ));
      await _db.into(_db.goals).insert(GoalsCompanion.insert(
        userId: userId,
        caloriesMin: caloriesMin,
        caloriesMax: caloriesMax,
        proteinG: proteinG,
        carbsG: carbsG,
        fatsG: fatsG,
      ));
    });
  }

  ({int caloriesMin, int caloriesMax, int proteinG, int carbsG, int fatsG}) suggestTargets({
    required int ageYears,
    required int heightCm,
    required double weightKg,
    required String gender,
    required String activityLevel,
    required String goalType, // 'bulk' | 'cut' | 'maintain'
  }) {
    // Very simple heuristic suggestions.
    final double weightLb = weightKg * 2.20462;
    final int proteinG = (weightLb * 0.8).round();

    // Basal estimate (rough): 24 * weightKg
    double base = 24 * weightKg;
    // Activity multiplier
    final mult = switch (activityLevel) {
      'Sedentary' => 1.2,
      'Lightly Active' => 1.375,
      'Active' => 1.55,
      'Very Active' => 1.725,
      _ => 1.55,
    };
    int maintenance = (base * mult).round();

    int delta = switch (goalType) {
      'bulk' => 500,
      'cut' => -500,
      _ => 0,
    };

    int target = maintenance + delta;
    int caloriesMin = (target * 0.98).round();
    int caloriesMax = (target * 1.02).round();

    // Macro split: protein fixed, fats ~30% cal, carbs rest
    int fatCalories = (target * 0.3).round();
    int fatsG = (fatCalories / 9).round();
    int proteinCalories = proteinG * 4;
    int carbsCalories = (target - proteinCalories - fatCalories).clamp(0, target);
    int carbsG = (carbsCalories / 4).round();

    return (
      caloriesMin: caloriesMin,
      caloriesMax: caloriesMax,
      proteinG: proteinG,
      carbsG: carbsG,
      fatsG: fatsG,
    );
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  return OnboardingRepository(db);
});
