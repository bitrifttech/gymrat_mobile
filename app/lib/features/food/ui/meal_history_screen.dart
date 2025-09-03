import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:go_router/go_router.dart';

class MealHistoryScreen extends ConsumerStatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  ConsumerState<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends ConsumerState<MealHistoryScreen> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 29));
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(_end.difference(_start).inDays + 1, (i) => _start.add(Duration(days: i))).reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final meals = ref.watch(mealsForDateProvider(day));
          final totals = ref.watch(totalsForDateProvider(day));
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('${day.month}/${day.day}/${day.year}'),
              subtitle: totals.when(
                loading: () => const SizedBox(height: 12, child: LinearProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
                data: (t) => Text('P ${t.proteinG}g • C ${t.carbsG}g • F ${t.fatsG}g  •  ${t.calories} kcal'),
              ),
              children: [
                meals.when(
                  loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
                  error: (e, st) => Padding(padding: const EdgeInsets.all(12), child: Text('Error: $e')),
                  data: (list) {
                    if (list.isEmpty) {
                      return const ListTile(title: Text('No meals logged'));
                    }
                    return Column(
                      children: [
                        for (final (meal, items) in list)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.restaurant_menu),
                                title: Text(_prettyMeal(meal.mealType)),
                              ),
                              for (final (item, food) in items)
                                ListTile(
                                  dense: true,
                                  title: Text(food.name),
                                  subtitle: Text('x ${item.quantity}  •  P ${item.proteinG}g • C ${item.carbsG}g • F ${item.fatsG}g'),
                                ),
                              const Divider(),
                            ],
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => context.pushNamed('food.log'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Food'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _prettyMeal(String t) {
    switch (t) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return t;
    }
  }
}
