import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key, this.initialMealType});
  final String? initialMealType;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _queryCtrl = TextEditingController();
  String _mealType = 'breakfast';

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null && widget.initialMealType!.isNotEmpty) {
      _mealType = widget.initialMealType!;
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _promptAdd(int foodId) async {
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    final result = await showDialog<(double qty, String? unit, String meal)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: _mealType,
              items: const [
                DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                DropdownMenuItem(value: 'snack', child: Text('Snack')),
              ],
              onChanged: (v) => setState(() => _mealType = v ?? 'breakfast'),
            ),
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
              Navigator.of(ctx).pop((q, u, _mealType));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final (qty, unit, meal) = result;
    await ref.read(foodRepositoryProvider).addExistingFoodToMeal(foodId: foodId, mealType: meal, quantity: qty, unit: unit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food added')));
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryCtrl.text.trim();
    final results = ref.watch(offSearchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Search Foods')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _queryCtrl,
              decoration: InputDecoration(
                hintText: 'Search e.g. chicken breast',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() {}),
                ),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (foods) {
                if (query.isEmpty) return const Center(child: Text('Enter a query to search'));
                if (foods.isEmpty) return const Center(child: Text('No results'));
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (ctx, i) {
                    final f = foods[i];
                    return Card(
                      child: ListTile(
                        title: Text(f.name),
                        subtitle: Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                        trailing: Text('${f.calories} kcal'),
                        onTap: () => _promptAdd(f.id),
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
}
