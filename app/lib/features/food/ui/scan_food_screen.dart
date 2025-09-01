import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/features/food/data/food_repository.dart';

class ScanFoodScreen extends ConsumerStatefulWidget {
  const ScanFoodScreen({super.key});
  @override
  ConsumerState<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends ConsumerState<ScanFoodScreen> {
  bool _handled = false;
  String _mealType = 'breakfast';

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
        );
      },
    );
    if (result == null) return;
    final (qty, unit, meal) = result;
    await ref.read(foodRepositoryProvider).addExistingFoodToMeal(foodId: foodId, mealType: meal, quantity: qty, unit: unit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food added')));
    Navigator.of(context).pop();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    setState(() => _handled = true);

    final repo = ref.read(foodRepositoryProvider);
    final id = await repo.fetchByBarcodeAndCache(code);
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not found')));
      setState(() => _handled = false);
      return;
    }
    await _promptAdd(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
