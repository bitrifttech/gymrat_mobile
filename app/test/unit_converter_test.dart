import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/food/data/unit_converter.dart';

void main() {
  group('UnitConverter.computeFactor', () {
    test('same unit weight', () {
      expect(UnitConverter.computeFactor(amount: 1, amountUnit: 'oz', baseAmount: 8, baseUnit: 'oz'), closeTo(0.125, 1e-9));
    });
    test('convert oz to g base', () {
      final f = UnitConverter.computeFactor(amount: 28.349523125, amountUnit: 'g', baseAmount: 1, baseUnit: 'oz');
      expect(f, closeTo(1.0, 1e-9));
    });
    test('volume tsp to cup', () {
      final f = UnitConverter.computeFactor(amount: 1, amountUnit: 'cup', baseAmount: 48, baseUnit: 'tsp');
      expect(f, closeTo(1.0, 1e-9));
    });
    test('serving linear', () {
      final f = UnitConverter.computeFactor(amount: 1, amountUnit: 'serving', baseAmount: 2, baseUnit: 'serving');
      expect(f, closeTo(0.5, 1e-9));
    });
  });
}


