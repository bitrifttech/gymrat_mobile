import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:go_router/go_router.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key, this.date});
  final DateTime? date;

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  String _mealType = 'breakfast';
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = widget.date == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(widget.date!.year, widget.date!.month, widget.date!.day);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Quantity/unit prompt, then add an existing food to the selected meal

  Future<void> _promptAndAddRecent({required int foodId}) async {
    final repo = ref.read(foodRepositoryProvider);
    final food = await repo.getFoodById(foodId);
    final qtyController = TextEditingController(text: (food?.servingQty?.toString() ?? '1'));
    String unitValue = _canonUnit(food?.servingUnit);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<(double qty, String? unit)>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (food?.servingQty != null && (food?.servingUnit ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Base serving: ${food!.servingQty} ${food.servingUnit}', style: Theme.of(ctx).textTheme.bodySmall),
                ),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: 'Decrease',
                    onPressed: () {
                      final currentVal = double.tryParse(qtyController.text) ?? 0;
                      final next = (currentVal - 1).clamp(0, double.infinity);
                      qtyController.text = next.toStringAsFixed(2);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Increase',
                    onPressed: () {
                      final currentVal = double.tryParse(qtyController.text) ?? 0;
                      final next = currentVal + 1;
                      qtyController.text = next.toStringAsFixed(2);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: unitValue,
                items: const [
                  DropdownMenuItem(value: 'serving', child: Text('serving')),
                  DropdownMenuItem(value: 'slice', child: Text('slice')),
                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                  DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                  DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                  DropdownMenuItem(value: 'fl oz', child: Text('Fluid ounce')),
                  DropdownMenuItem(value: 'cup', child: Text('cup')),
                  DropdownMenuItem(value: 'g', child: Text('gram (g)')),
                  DropdownMenuItem(value: 'oz', child: Text('oz')),
                ],
                onChanged: (v) => unitValue = v ?? unitValue,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final frac in const [
                      ('1/4', 0.25),
                      ('1/3', 1.0/3.0),
                      ('1/2', 0.5),
                      ('2/3', 2.0/3.0),
                      ('3/4', 0.75),
                    ])
                      ActionChip(
                        label: Text(frac.$1),
                        onPressed: () {
                          final baseQty = food?.servingQty;
                          final baseUnit = _canonUnit(food?.servingUnit);
                          final selectedUnit = _canonUnit(unitValue);
                          double newQty;
                          if (baseQty != null && baseUnit.isNotEmpty && selectedUnit == baseUnit) {
                            newQty = baseQty * frac.$2;
                          } else {
                            newQty = frac.$2;
                          }
                          qtyController.text = newQty.toStringAsFixed(2);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final q = double.tryParse(qtyController.text) ?? 1.0;
                final u = (unitValue.trim().isEmpty ? null : unitValue.trim());
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
    await repo.addExistingFoodToMealOnDate(date: _date, foodId: foodId, mealType: _mealType, quantity: qty, unit: unit);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Food added')));
  }

  // Canonicalize arbitrary unit strings to supported dropdown values
  String _canonUnit(String? u) {
    final v = (u ?? 'serving').trim().toLowerCase();
    switch (v) {
      case 'g':
      case 'gram':
      case 'grams':
        return 'g';
      case 'oz':
      case 'ounce':
      case 'ounces':
        return 'oz';
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        return 'ml';
      case 'tsp':
      case 'teaspoon':
      case 'teaspoons':
        return 'tsp';
      case 'tbsp':
      case 'tablespoon':
      case 'tablespoons':
        return 'tbsp';
      case 'fl oz':
      case 'floz':
      case 'fluid ounce':
      case 'fluid ounces':
        return 'fl oz';
      case 'cup':
      case 'cups':
        return 'cup';
      case 'serving':
      case 'servings':
      default:
        return 'serving';
    }
  }

  ButtonStyle _mealBtnStyle(String type, BuildContext context) {
    final selected = _mealType == type;
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: selected ? scheme.primary : null,
      foregroundColor: selected ? scheme.onPrimary : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsForDateProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Log Food — ${_date.month}/${_date.day}/${_date.year}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: _mealBtnStyle('breakfast', context),
                    onPressed: () => setState(() => _mealType = 'breakfast'),
                    child: const Text('Breakfast'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: _mealBtnStyle('lunch', context),
                    onPressed: () => setState(() => _mealType = 'lunch'),
                    child: const Text('Lunch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: _mealBtnStyle('dinner', context),
                    onPressed: () => setState(() => _mealType = 'dinner'),
                    child: const Text('Dinner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: _mealBtnStyle('snack', context),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name, style: Theme.of(context).textTheme.bodyLarge),
                                  if ((f.brand ?? '').isNotEmpty || (f.servingDesc ?? '').isNotEmpty)
                                    Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                                  Text('Qty ${mi.quantity.toStringAsFixed(2)}${(mi.unit == null || mi.unit!.trim().isEmpty) ? '' : ' ${mi.unit}'}'),
                                  Text('P ${mi.proteinG}g • C ${mi.carbsG}g • F ${mi.fatsG}g'),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${mi.calories} kcal'),
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final r = await showDialog<(double, String?)>(
                                      context: context,
                                      builder: (ctx) {
                                        final qtyCtrl = TextEditingController(text: mi.quantity.toStringAsFixed(2));
                                        String unitVal = _canonUnit(mi.unit ?? f.servingUnit);
                                        return AlertDialog(
                                          title: const Text('Edit Item'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(controller: qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantity'), textInputAction: TextInputAction.done),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  IconButton(onPressed: () { final v = (double.tryParse(qtyCtrl.text) ?? 0) - 1; qtyCtrl.text = (v < 0 ? 0 : v).toStringAsFixed(0); }, icon: const Icon(Icons.remove_circle_outline)),
                                                  IconButton(onPressed: () { final v = (double.tryParse(qtyCtrl.text) ?? 0) + 1; qtyCtrl.text = v.toStringAsFixed(0); }, icon: const Icon(Icons.add_circle_outline)),
                                                ],
                                              ),
                                              DropdownButtonFormField<String>(
                                                value: unitVal,
                                                items: const [
                                                  DropdownMenuItem(value: 'serving', child: Text('serving')),
                                                  DropdownMenuItem(value: 'slice', child: Text('slice')),
                                                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                                                  DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                                                  DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                                                  DropdownMenuItem(value: 'fl oz', child: Text('fl oz')),
                                                  DropdownMenuItem(value: 'cup', child: Text('cup')),
                                                  DropdownMenuItem(value: 'g', child: Text('g')),
                                                  DropdownMenuItem(value: 'oz', child: Text('oz')),
                                                ],
                                                onChanged: (v) => unitVal = v ?? unitVal,
                                                decoration: const InputDecoration(labelText: 'Unit'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                final q = double.tryParse(qtyCtrl.text) ?? mi.quantity;
                                                Navigator.pop(ctx, (q, unitVal));
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (r != null) {
                                      final (q, u) = r;
                                      await ref.read(foodRepositoryProvider).updateItemQuantityAndUnit(itemId: mi.id, quantity: q, unit: u);
                                    }
                                  },
                                ),
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
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('New custom food'),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            final newId = await _createCustomFoodDialog();
                            if (newId != null) {
                              await _promptAndAddRecent(foodId: newId);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: foods.isEmpty
                              ? const Center(child: Text('No custom foods yet'))
                              : ListView.builder(
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
                                ),
                        ),
                      ],
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

  Future<int?> _createCustomFoodDialog() async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final serving = TextEditingController();
    final servingQty = TextEditingController();
    String servingUnit = 'serving';
    final cal = TextEditingController();
    final p = TextEditingController();
    final c = TextEditingController();
    final f = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Custom Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand')),
              TextField(controller: serving, decoration: const InputDecoration(labelText: 'Serving desc')),
              Row(children: [
                Expanded(child: TextField(controller: servingQty, decoration: const InputDecoration(labelText: 'Serving qty'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: servingUnit,
                    items: const [
                      DropdownMenuItem(value: 'serving', child: Text('serving')),
                      DropdownMenuItem(value: 'slice', child: Text('slice')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                      DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                      DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                      DropdownMenuItem(value: 'fl oz', child: Text('Fluid ounce')),
                      DropdownMenuItem(value: 'cup', child: Text('cup')),
                      DropdownMenuItem(value: 'g', child: Text('gram')),
                      DropdownMenuItem(value: 'oz', child: Text('oz')),
                    ],
                    onChanged: (v) => servingUnit = v ?? 'serving',
                    decoration: const InputDecoration(labelText: 'Serving unit'),
                  ),
                ),
              ]),
              TextField(controller: cal, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(controller: p, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(controller: c, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(controller: f, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final id = await ref.read(foodRepositoryProvider).addCustomFood(
            name: name.text.trim(),
            brand: brand.text.trim().isEmpty ? null : brand.text.trim(),
            servingDesc: serving.text.trim().isEmpty ? null : serving.text.trim(),
            servingQty: double.tryParse(servingQty.text.trim()),
            servingUnit: servingUnit,
            calories: int.tryParse(cal.text) ?? 0,
            proteinG: int.tryParse(p.text) ?? 0,
            carbsG: int.tryParse(c.text) ?? 0,
            fatsG: int.tryParse(f.text) ?? 0,
          );
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food created')));
      return id;
    }
    return null;
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
      final ds = '${_date.year.toString().padLeft(4,'0')}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
      context.push('/food/search?meal='+_mealType+'&date='+ds);
    } else if (action == 'scan') {
      if (!mounted) return;
      final ds = '${_date.year.toString().padLeft(4,'0')}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}';
      context.push('/food/scan?meal='+_mealType+'&date='+ds);
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
