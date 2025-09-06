class UnitConverter {
  static double computeFactor({
    required double amount,
    required String amountUnit,
    required double baseAmount,
    required String baseUnit,
  }) {
    final uA = _normalizeUnit(amountUnit);
    final uB = _normalizeUnit(baseUnit);
    if (uA == 'serving' && uB == 'serving') {
      return amount / baseAmount;
    }
    if (uA == uB) {
      return amount / baseAmount;
    }
    if (_isWeight(uA) && _isWeight(uB)) {
      final aG = _toGrams(amount, uA);
      final bG = _toGrams(baseAmount, uB);
      if (bG == 0) return amount;
      return aG / bG;
    }
    if (_isVolume(uA) && _isVolume(uB)) {
      final aMl = _toMilliliters(amount, uA);
      final bMl = _toMilliliters(baseAmount, uB);
      if (bMl == 0) return amount;
      return aMl / bMl;
    }
    return amount;
  }

  static String _normalizeUnit(String u) {
    final v = u.trim().toLowerCase();
    switch (v) {
      case 'g':
      case 'gram':
      case 'grams':
        return 'g';
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        return 'kg';
      case 'oz':
      case 'ounce':
      case 'ounces':
        return 'oz';
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        return 'lb';
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        return 'ml';
      case 'l':
      case 'liter':
      case 'liters':
        return 'l';
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
        return 'serving';
      default:
        return v;
    }
  }

  static bool _isWeight(String u) => u == 'g' || u == 'kg' || u == 'oz' || u == 'lb';
  static bool _isVolume(String u) => u == 'ml' || u == 'l' || u == 'tsp' || u == 'tbsp' || u == 'fl oz' || u == 'cup';

  static double _toGrams(double qty, String unit) {
    switch (unit) {
      case 'g':
        return qty;
      case 'kg':
        return qty * 1000.0;
      case 'oz':
        return qty * 28.349523125;
      case 'lb':
        return qty * 453.59237;
      default:
        return qty;
    }
  }

  static double _toMilliliters(double qty, String unit) {
    switch (unit) {
      case 'ml':
        return qty;
      case 'l':
        return qty * 1000.0;
      case 'tsp':
        return qty * 5.0;
      case 'tbsp':
        return qty * 15.0;
      case 'fl oz':
        return qty * 29.5735295625;
      case 'cup':
        return qty * 240.0;
      default:
        return qty;
    }
  }
}


