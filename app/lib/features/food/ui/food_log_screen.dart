import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:go_router/go_router.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  String _mealType = 'breakfast';

  @override
  void dispose() {
    super.dispose();
  }

  // Quantity/unit prompt, then add an existing food to the selected meal

  Future<void> _promptAndAddRecent({required int foodId}) async {
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<(double qty, String? unit)>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final q = double.tryParse(qtyController.text) ?? 1.0;
                final u = unitController.text.trim().isEmpty ? null : unitController.text.trim();
                Navigator.of(ctx).pop((q, u));
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    final (qty, unit) = result;
    final repo = ref.read(foodRepositoryProvider);
    await repo.addExistingFoodToMeal(foodId: foodId, mealType: _mealType, quantity: qty, unit: unit);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Food added')));
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(todaysMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Food'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mealType = 'breakfast'),
                    child: const Text('Breakfast'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mealType = 'lunch'),
                    child: const Text('Lunch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mealType = 'dinner'),
                    child: const Text('Dinner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mealType = 'snack'),
                    child: const Text('Snack'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCustomFoodsPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Food'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openSearchOrScan,
                    icon: const Icon(Icons.search),
                    label: const Text('Search For Food'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: meals.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (dayMeals) {
                final match = dayMeals.where((m) => m.$1.mealType == _mealType).toList();
                if (match.isEmpty || match.first.$2.isEmpty) {
                  return Center(child: Text('No foods in ${_prettyMeal(_mealType)} yet'));
                }
                final items = match.first.$2;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final (mi, f) = items[i];
                    return Card(
                      child: ListTile(
                        title: Text(f.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((f.brand ?? '').isNotEmpty || (f.servingDesc ?? '').isNotEmpty)
                              Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                            if (f.servingQty != null && (f.servingUnit ?? '').isNotEmpty)
                              Text('Serving: ${f.servingQty} ${f.servingUnit}'),
                            Text('Qty ${mi.quantity.toStringAsFixed(2)}${mi.unit == null ? '' : ' ${mi.unit}'} • P ${mi.proteinG}g • C ${mi.carbsG}g • F ${mi.fatsG}g'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${mi.calories} kcal'),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove item?'),
                                    content: Text('Remove "${f.name}" from ${_prettyMeal(_mealType)}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await ref.read(foodRepositoryProvider).deleteMealItem(mi.id);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomFoodsPicker() async {
    final foodId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Consumer(
              builder: (context, ref, _) {
                final customFoods = ref.watch(customFoodsProvider);
                return customFoods.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                  data: (foods) {
                    if (foods.isEmpty) {
                      return const Center(child: Text('No custom foods yet'));
                    }
                    return ListView.builder(
                      itemCount: foods.length,
                      itemBuilder: (c, i) {
                        final f = foods[i];
                        return ListTile(
                          title: Text(f.name),
                          subtitle: Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                          trailing: Text('${f.calories} kcal'),
                          onTap: () => Navigator.of(ctx).pop(f.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
    if (foodId != null) {
      await _promptAndAddRecent(foodId: foodId);
    }
  }

  Future<void> _openSearchOrScan() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Foods'),
                onTap: () => Navigator.of(ctx).pop('search'),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Barcode'),
                onTap: () => Navigator.of(ctx).pop('scan'),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'search') {
      if (!mounted) return;
      context.push('/food/search?meal='+_mealType);
    } else if (action == 'scan') {
      if (!mounted) return;
      context.push('/food/scan?meal='+_mealType);
    }
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
