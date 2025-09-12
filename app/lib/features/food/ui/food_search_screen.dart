import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key, this.initialMealType, this.initialDate});
  final String? initialMealType;
  final DateTime? initialDate;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _queryCtrl = TextEditingController();
  String _mealType = 'breakfast';
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null && widget.initialMealType!.isNotEmpty) {
      _mealType = widget.initialMealType!;
    }
    final now = DateTime.now();
    _date = widget.initialDate == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day);
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
      builder: (ctx) {
        double sliderVal = double.tryParse(qtyController.text) ?? 1.0;
        const int maxInt = 99999;
        int initialIntPart = sliderVal.floor().clamp(0, maxInt);
        double rem = sliderVal - initialIntPart;
        final List<double> fr = [0.0, 0.125, 0.25, 1.0/3.0, 0.5, 2.0/3.0, 0.75];
        int initialFracIdx = 0; double bestDiff = 1e9; for (int i = 0; i < fr.length; i++) { final d = (rem - fr[i]).abs(); if (d < bestDiff) { bestDiff = d; initialFracIdx = i; } }
        final FixedExtentScrollController intCtrl = FixedExtentScrollController(initialItem: initialIntPart);
        final FixedExtentScrollController fracCtrl = FixedExtentScrollController(initialItem: initialFracIdx);
        return StatefulBuilder(builder: (ctx, setStateSB) {
          return AlertDialog(
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? sliderVal;
                    setStateSB(() => sliderVal = d < 0 ? 0 : d);
                    // Sync wheels
                    final intPart = sliderVal.floor().clamp(0, maxInt);
                    int fracIdx = 0; double best = 1e9; final rem2 = sliderVal - intPart;
                    for (int i = 0; i < fr.length; i++) { final dd = (rem2 - fr[i]).abs(); if (dd < best) { best = dd; fracIdx = i; } }
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
                                final fIdx = fracCtrl.selectedItem;
                                final val = idx + fr[fIdx];
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
          );
        });
      },
    );
    if (result == null) return;
    final (qty, unit, meal) = result;
    await ref.read(foodRepositoryProvider).addExistingFoodToMealOnDate(date: _date, foodId: foodId, mealType: meal, quantity: qty, unit: unit);
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
