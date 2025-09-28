import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        double sliderVal = double.tryParse(qtyController.text) ?? 1.0;
        // Rotary (wheel) picker controllers
        const int maxInt = 99999;
        int initialIntPart = sliderVal.floor().clamp(0, maxInt);
        double rem = sliderVal - initialIntPart;
        final List<double> fr = [0.0, 0.125, 0.25, 1.0/3.0, 0.5, 2.0/3.0, 0.75];
        int initialFracIdx = 0; double bestDiff = 1e9;
        for (int i = 0; i < fr.length; i++) { final d = (rem - fr[i]).abs(); if (d < bestDiff) { bestDiff = d; initialFracIdx = i; } }
        final FixedExtentScrollController intCtrl = FixedExtentScrollController(initialItem: initialIntPart);
        final FixedExtentScrollController fracCtrl = FixedExtentScrollController(initialItem: initialFracIdx);
        return StatefulBuilder(builder: (ctx, setStateSB) {
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
                onChanged: (v) {
                  final d = double.tryParse(v) ?? sliderVal;
                  setStateSB(() => sliderVal = d < 0 ? 0 : d);
                  // Sync wheels to typed value
                  final intPart = sliderVal.floor().clamp(0, maxInt);
                  int fracIdx = 0; double best = 1e9; final rem2 = sliderVal - intPart;
                  for (int i = 0; i < fr.length; i++) { final d = (rem2 - fr[i]).abs(); if (d < best) { best = d; fracIdx = i; } }
                  intCtrl.jumpToItem(intPart);
                  fracCtrl.jumpToItem(fracIdx);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ListWheelScrollView.useDelegate(
                            controller: intCtrl,
                            physics: const FixedExtentScrollPhysics(),
                            itemExtent: 36,
                            onSelectedItemChanged: (idx) {
                              final fracIdx = fracCtrl.selectedItem;
                              final val = idx + fr[fracIdx];
                              setStateSB(() {
                                sliderVal = val;
                                qtyController.text = val.toStringAsFixed(2);
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: maxInt + 1,
                              builder: (ctx, idx) {
                                final bool isSel = idx == intCtrl.selectedItem;
                                return Center(
                                  child: Text(
                                    idx.toString(),
                                    style: TextStyle(fontSize: isSel ? 18 : 14, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal),
                                  ),
                                );
                              },
                            ),
                          ),
                          const IgnorePointer(child: CupertinoPickerDefaultSelectionOverlay()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ListWheelScrollView.useDelegate(
                            controller: fracCtrl,
                            physics: const FixedExtentScrollPhysics(),
                            itemExtent: 36,
                            onSelectedItemChanged: (fIdx) {
                              final intPart = intCtrl.selectedItem;
                              final val = intPart + fr[fIdx];
                              setStateSB(() {
                                sliderVal = val;
                                qtyController.text = val.toStringAsFixed(2);
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 7,
                              builder: (ctx, idx) {
                                const labels = ['0','1/8','1/4','1/3','1/2','2/3','3/4'];
                                final bool isSel = idx == fracCtrl.selectedItem;
                                return Center(
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(fontSize: isSel ? 18 : 14, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal),
                                  ),
                                );
                              },
                            ),
                          ),
                          const IgnorePointer(child: CupertinoPickerDefaultSelectionOverlay()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
        });
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

  

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsForDateProvider(_date));
    final perMealTotals = ref.watch(perMealTotalsForDateProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Log Food — ${_date.month}/${_date.day}/${_date.year}'),
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                perMealTotals.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (totals) {
                    int getKcal(String t) => totals.firstWhere((x) => x.mealType == t, orElse: () => const MealTotals(mealType: '', calories: 0, proteinG: 0, carbsG: 0, fatsG: 0)).calories;
                    int getP(String t) => totals.firstWhere((x) => x.mealType == t, orElse: () => const MealTotals(mealType: '', calories: 0, proteinG: 0, carbsG: 0, fatsG: 0)).proteinG;
                    int getC(String t) => totals.firstWhere((x) => x.mealType == t, orElse: () => const MealTotals(mealType: '', calories: 0, proteinG: 0, carbsG: 0, fatsG: 0)).carbsG;
                    int getF(String t) => totals.firstWhere((x) => x.mealType == t, orElse: () => const MealTotals(mealType: '', calories: 0, proteinG: 0, carbsG: 0, fatsG: 0)).fatsG;
                    Widget tile(String t, String label) {
                      final selected = _mealType == t;
                      final scheme = Theme.of(context).colorScheme;
                      final bg = selected ? scheme.primaryContainer : Theme.of(context).cardColor;
                      final fg = Theme.of(context).colorScheme.onSurface;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mealType = t),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selected ? scheme.primary : Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: 4),
                                Text('${getKcal(t)} kcal', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg)),
                                const SizedBox(height: 2),
                                Text('P ${getP(t)} • C ${getC(t)} • F ${getF(t)}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Row(
                      children: [
                        tile('breakfast', 'Breakfast'),
                        tile('lunch', 'Lunch'),
                        tile('dinner', 'Dinner'),
                        tile('snack', 'Snack'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
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
