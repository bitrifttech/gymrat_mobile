import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/onboarding/data/onboarding_repository.dart';
import 'package:app/features/settings/data/settings_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  // Units
  String _units = 'metric';

  // Profile
  final TextEditingController _age = TextEditingController(text: '30');
  final TextEditingController _height = TextEditingController(text: '178');
  final TextEditingController _weight = TextEditingController(text: '80');
  String _sex = 'Male';
  String _activity = 'Active';

  // Goal
  String _goal = 'maintain';

  // Macros controllers (user-editable)
  final TextEditingController _calMinCtrl = TextEditingController();
  final TextEditingController _calMaxCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _fatsCtrl = TextEditingController();

  bool _busy = false;
  bool _macrosHydrated = false;

  void _fillSuggestions() {
    final repo = ref.read(onboardingRepositoryProvider);
    final s = repo.suggestTargets(
      ageYears: int.tryParse(_age.text) ?? 30,
      heightCm: _units == 'metric' ? (int.tryParse(_height.text) ?? 178) : _inchToCm(_height.text) ?? 178,
      weightKg: _units == 'metric' ? (double.tryParse(_weight.text) ?? 80) : _lbToKg(_weight.text) ?? 80,
      gender: _sex,
      activityLevel: _activity,
      goalType: _goal,
    );
    _calMinCtrl.text = s.caloriesMin.toString();
    _calMaxCtrl.text = s.caloriesMax.toString();
    _proteinCtrl.text = s.proteinG.toString();
    _carbsCtrl.text = s.carbsG.toString();
    _fatsCtrl.text = s.fatsG.toString();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final heightCm = _units == 'metric' ? int.tryParse(_height.text) : _inchToCm(_height.text);
      final weightKg = _units == 'metric' ? double.tryParse(_weight.text) : _lbToKg(_weight.text);

      await ref.read(onboardingRepositoryProvider).saveOnboarding(
        ageYears: int.tryParse(_age.text) ?? 30,
        heightCm: heightCm ?? 178,
        weightKg: weightKg ?? 80,
        gender: _sex,
        activityLevel: _activity,
        caloriesMin: int.tryParse(_calMinCtrl.text) ?? 2000,
        caloriesMax: int.tryParse(_calMaxCtrl.text) ?? 2200,
        proteinG: int.tryParse(_proteinCtrl.text) ?? 150,
        carbsG: int.tryParse(_carbsCtrl.text) ?? 250,
        fatsG: int.tryParse(_fatsCtrl.text) ?? 70,
      );
      // Persist units preference
      await ref.read(settingsRepositoryProvider).setUnits(_units);
      if (mounted) context.goNamed('home');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int? _inchToCm(String input) {
    final v = double.tryParse(input);
    if (v == null) return null;
    return (v * 2.54).round();
  }

  double? _lbToKg(String input) {
    final v = double.tryParse(input);
    if (v == null) return null;
    return (v * 0.45359237);
  }

  String _cmToInText(int cm) => (cm / 2.54).toStringAsFixed(1);
  String _kgToLbText(double kg) => (kg / 0.45359237).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            setState(() => _step = 1);
          } else if (_step == 1) {
            // Entering macros step. Hydrate suggestions only once if empty
            if (!_macrosHydrated) {
              _fillSuggestions();
              _macrosHydrated = true;
            }
            setState(() => _step = 2);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step -= 1);
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(onPressed: _busy ? null : details.onStepContinue, child: Text(_step < 2 ? 'Next' : (_busy ? 'Saving...' : 'Finish'))),
              const SizedBox(width: 8),
              if (_step > 0) TextButton(onPressed: _busy ? null : details.onStepCancel, child: const Text('Back')),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Profile'),
            isActive: _step >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Units:'),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(value: 'metric', label: Text('Metric')),
                        ButtonSegment<String>(value: 'imperial', label: Text('Imperial')),
                      ],
                      selected: {_units},
                      onSelectionChanged: (set) async {
                        final v = set.first;
                        setState(() => _units = v);
                        await ref.read(settingsRepositoryProvider).setUnits(v);
                        // Convert current display values to selected units (for user input convenience)
                        if (v == 'imperial') {
                          final hCm = int.tryParse(_height.text);
                          if (hCm != null) _height.text = _cmToInText(hCm);
                          final wKg = double.tryParse(_weight.text);
                          if (wKg != null) _weight.text = _kgToLbText(wKg);
                        } else {
                          final cm = _inchToCm(_height.text);
                          if (cm != null) _height.text = cm.toString();
                          final kg = _lbToKg(_weight.text);
                          if (kg != null) _weight.text = kg.toStringAsFixed(1);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(decoration: const InputDecoration(labelText: 'Age (years)'), keyboardType: TextInputType.number, controller: _age),
                TextField(
                  decoration: InputDecoration(labelText: _units == 'metric' ? 'Height (cm)' : 'Height (in)'),
                  keyboardType: TextInputType.number,
                  controller: _height,
                ),
                TextField(
                  decoration: InputDecoration(labelText: _units == 'metric' ? 'Weight (kg)' : 'Weight (lb)'),
                  keyboardType: TextInputType.number,
                  controller: _weight,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female'))],
                  onChanged: (v) => setState(() => _sex = v ?? 'Male'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _activity,
                  decoration: const InputDecoration(labelText: 'Activity Level'),
                  items: const [
                    DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary')),
                    DropdownMenuItem(value: 'Lightly Active', child: Text('Lightly Active')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Very Active', child: Text('Very Active')),
                  ],
                  onChanged: (v) => setState(() => _activity = v ?? 'Active'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Goal'),
            isActive: _step >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(value: 'bulk', label: Text('Bulk')),
                    ButtonSegment<String>(value: 'cut', label: Text('Cut')),
                    ButtonSegment<String>(value: 'maintain', label: Text('Maintain')),
                  ],
                  selected: {_goal},
                  onSelectionChanged: (set) => setState(() => _goal = set.first),
                ),
                const SizedBox(height: 8),
                Text(
                  switch (_goal) {
                    'bulk' => '+500 calories (gain)',
                    'cut' => '-500 calories (lose)',
                    _ => 'Maintain current weight',
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Macros'),
            isActive: _step >= 2,
            content: Column(
              children: [
                TextField(decoration: const InputDecoration(labelText: 'Calories Min'), keyboardType: TextInputType.number, controller: _calMinCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Calories Max'), keyboardType: TextInputType.number, controller: _calMaxCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number, controller: _proteinCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number, controller: _carbsCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number, controller: _fatsCtrl),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _fillSuggestions, child: const Text('Use Suggestions')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
