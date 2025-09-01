import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();

  String _mealType = 'breakfast';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _servingCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(foodRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
    await repo.addCustomFoodToMeal(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      servingDesc: _servingCtrl.text.trim().isEmpty ? null : _servingCtrl.text.trim(),
      calories: int.parse(_calCtrl.text),
      proteinG: int.parse(_proteinCtrl.text),
      carbsG: int.parse(_carbCtrl.text),
      fatsG: int.parse(_fatCtrl.text),
      mealType: _mealType,
      quantity: qty,
      unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
    );
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Food added')));
    _formKey.currentState!.reset();
    _nameCtrl.clear();
    _brandCtrl.clear();
    _servingCtrl.clear();
    _calCtrl.clear();
    _proteinCtrl.clear();
    _carbCtrl.clear();
    _fatCtrl.clear();
    _qtyCtrl.text = '1';
    _unitCtrl.clear();
  }

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
    final recent = ref.watch(recentFoodsProvider);
    final perMeal = ref.watch(todayPerMealTotalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Food')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 16),
          Text('Add Custom Food', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand (optional)'),
                ),
                TextFormField(
                  controller: _servingCtrl,
                  decoration: const InputDecoration(labelText: 'Serving (e.g., 1 cup)'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _calCtrl,
                        decoration: const InputDecoration(labelText: 'Calories'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _proteinCtrl,
                        decoration: const InputDecoration(labelText: 'Protein (g)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _carbCtrl,
                        decoration: const InputDecoration(labelText: 'Carbs (g)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fatCtrl,
                        decoration: const InputDecoration(labelText: 'Fats (g)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Meal'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          recent.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )),
            error: (e, st) => Text('Error: $e'),
            data: (foods) {
              if (foods.isEmpty) return const Text('No recent foods');
              return Column(
                children: [
                  for (final f in foods)
                    Card(
                      child: ListTile(
                        title: Text(f.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((f.brand ?? '').isNotEmpty || (f.servingDesc ?? '').isNotEmpty)
                              Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                            Text('P ${f.proteinG}g • C ${f.carbsG}g • F ${f.fatsG}g'),
                          ],
                        ),
                        trailing: Text('${f.calories} kcal'),
                        onTap: () => _promptAndAddRecent(foodId: f.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Per-meal Subtotals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          perMeal.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )),
            error: (e, st) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('No items logged today');
              return Column(
                children: [
                  for (final m in list)
                    ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(_prettyMeal(m.mealType)),
                      subtitle: Text('P ${m.proteinG}g • C ${m.carbsG}g • F ${m.fatsG}g'),
                      trailing: Text('${m.calories} kcal'),
                    ),
                ],
              );
            },
          ),
        ],
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
