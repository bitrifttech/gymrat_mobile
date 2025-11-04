import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/core/app_theme.dart';

class MealsAtDateScreen extends ConsumerWidget {
  const MealsAtDateScreen({super.key, required this.date});
  final DateTime date;

  String _prettyMeal(String t) {
    switch (t) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snack': return 'Snack';
      default: return t;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsForDateProvider(date));
    final totals = ref.watch(totalsForDateProvider(date));
    return Scaffold(
      appBar: GradientAppBar(
        title: Text('${date.month}/${date.day}/${date.year}'),
        gradient: AppBarGradients.all,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Reuse FoodLog to add for today; editing by arbitrary date is handled via repository method where needed
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Meal History or search to add foods.')));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          totals.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (t) => ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Totals'),
              subtitle: Text('P ${t.proteinG}g • C ${t.carbsG}g • F ${t.fatsG}g  •  ${t.calories} kcal'),
            ),
          ),
          const SizedBox(height: 8),
          meals.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) return const Center(child: Text('No meals for this day'));
              return Column(
                children: [
                  for (final (meal, items) in list)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(_prettyMeal(meal.mealType)),
                        children: [
                          for (final (item, food) in items)
                            ListTile(
                              title: Text(food.name),
                              subtitle: Text('x ${item.quantity}  •  P ${item.proteinG}g • C ${item.carbsG}g • F ${item.fatsG}g'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref.read(foodRepositoryProvider).deleteMealItem(item.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


