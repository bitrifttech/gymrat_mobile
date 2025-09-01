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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found item: #$id')));
    Navigator.of(context).pop();
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
