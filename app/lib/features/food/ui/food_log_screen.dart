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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(foodRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.addCustomFoodToMeal(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      servingDesc: _servingCtrl.text.trim().isEmpty ? null : _servingCtrl.text.trim(),
      calories: int.parse(_calCtrl.text),
      proteinG: int.parse(_proteinCtrl.text),
      carbsG: int.parse(_carbCtrl.text),
      fatsG: int.parse(_fatCtrl.text),
      mealType: _mealType,
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
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentFoodsProvider);

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
                        subtitle: Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                        trailing: Text('${f.calories} kcal'),
                        onTap: () async {
                          final repo = ref.read(foodRepositoryProvider);
                          final messenger = ScaffoldMessenger.of(context);
                          await repo.addExistingFoodToMeal(foodId: f.id, mealType: _mealType);
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text('Added ${f.name}')));
                        },
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
