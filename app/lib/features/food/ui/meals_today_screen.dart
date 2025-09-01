import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/food/data/food_repository.dart';

class MealsTodayScreen extends ConsumerWidget {
  const MealsTodayScreen({super.key});

  Future<void> _editQtyDialog(BuildContext context, WidgetRef ref, int itemId, double currentQty) async {
    final controller = TextEditingController(text: currentQty.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final q = double.tryParse(controller.text) ?? currentQty;
              Navigator.of(ctx).pop(q);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref.read(foodRepositoryProvider).updateItemQuantity(itemId: itemId, quantity: result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaysMealsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Meals")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('food.log'),
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
      body: today.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (meals) {
          if (meals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No meals yet today'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.pushNamed('food.log'),
                    child: const Text('Add Food'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final (meal, items) = meals[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text(_prettyMeal(meal.mealType)),
                  subtitle: FutureBuilder<MealTotals?>(
                    future: ref.read(foodRepositoryProvider).watchTodayPerMealTotals().first.then((list) => list.firstWhere(
                          (t) => t.mealType == meal.mealType,
                          orElse: () => const MealTotals(mealType: '', calories: 0, proteinG: 0, carbsG: 0, fatsG: 0),
                        )),
                    builder: (ctx, snap) {
                      final t = snap.data;
                      if (t == null || t.mealType.isEmpty) return const SizedBox.shrink();
                      return Text('P ${t.proteinG}g • C ${t.carbsG}g • F ${t.fatsG}g  •  ${t.calories} kcal');
                    },
                  ),
                  children: [
                    for (final (item, food) in items)
                      ListTile(
                        title: Text(food.name),
                        subtitle: Text('x ${item.quantity}  •  P ${item.proteinG}g • C ${item.carbsG}g • F ${item.fatsG}g'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit quantity',
                              onPressed: () => _editQtyDialog(context, ref, item.id, item.quantity),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Remove',
                              onPressed: () => ref.read(foodRepositoryProvider).deleteMealItem(item.id),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.pushNamed('food.log'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add more food'),
                      ),
                    ),
                  ],
                ),
              );
            },
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
