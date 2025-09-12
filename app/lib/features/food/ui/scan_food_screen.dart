import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/features/food/data/food_repository.dart';

class ScanFoodScreen extends ConsumerStatefulWidget {
  const ScanFoodScreen({super.key, this.initialMealType, this.initialDate});
  final String? initialMealType;
  final DateTime? initialDate;
  @override
  ConsumerState<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends ConsumerState<ScanFoodScreen> {
  bool _handled = false;
  String _mealType = 'breakfast';
  late DateTime _date;
  bool _liveDetected = false;

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

  Future<void> _promptAdd(int foodId) async {
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    final result = await showDialog<(double qty, String? unit, String meal)>(
      context: context,
      builder: (ctx) {
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease',
                    onPressed: () {
                      final v = (double.tryParse(qtyController.text) ?? 0) - 1;
                      qtyController.text = (v < 0 ? 0 : v).toStringAsFixed(2);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Increase',
                    onPressed: () {
                      final v = (double.tryParse(qtyController.text) ?? 0) + 1;
                      qtyController.text = v.toStringAsFixed(2);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
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
                          qtyController.text = frac.$2.toStringAsFixed(2);
                        },
                      ),
                  ],
                ),
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
        );
      },
    );
    if (result == null) return;
    final (qty, unit, meal) = result;
    await ref.read(foodRepositoryProvider).addExistingFoodToMealOnDate(date: _date, foodId: foodId, mealType: meal, quantity: qty, unit: unit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food added')));
    Navigator.of(context).pop();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    setState(() => _liveDetected = true);
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    setState(() => _handled = true);

    final repo = ref.read(foodRepositoryProvider);
    final id = await repo.fetchByBarcodeAndCache(code);
    if (!mounted) return;
    if (id == null) {
      // Fallback: create custom food from barcode
      final create = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Food not found'),
          content: const Text('Create a custom food with this barcode?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Create')),
          ],
        ),
      );
      if (create == true) {
        final name = TextEditingController();
        final brand = TextEditingController();
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
          final newId = await ref.read(foodRepositoryProvider).addCustomFood(
                name: name.text.trim().isEmpty ? 'Custom Food' : name.text.trim(),
                brand: brand.text.trim().isEmpty ? null : brand.text.trim(),
                servingDesc: '100 g',
                servingQty: 100,
                servingUnit: 'g',
                calories: int.tryParse(cal.text) ?? 0,
                proteinG: int.tryParse(p.text) ?? 0,
                carbsG: int.tryParse(c.text) ?? 0,
                fatsG: int.tryParse(f.text) ?? 0,
                barcode: code,
              );
          if (!mounted) return;
          await _promptAdd(newId);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not found')));
      setState(() { _handled = false; _liveDetected = false; });
      return;
    }
    await _promptAdd(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double boxWidth = width * 0.8;
          final double boxHeight = height * 0.28;
          final double left = (width - boxWidth) / 2;
          final double top = (height - boxHeight) / 3; // a bit higher than center
          final Rect scanRect = Rect.fromLTWH(left, top, boxWidth, boxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                onDetect: _onDetect,
                scanWindow: scanRect,
              ),
              // Framing box overlay
              Positioned(
                left: left,
                top: top,
                width: boxWidth,
                height: boxHeight,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _liveDetected ? Colors.greenAccent : Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
