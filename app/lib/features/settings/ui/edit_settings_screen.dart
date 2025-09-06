import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/settings/data/settings_repository.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EditSettingsScreen extends ConsumerStatefulWidget {
  const EditSettingsScreen({super.key});

  @override
  ConsumerState<EditSettingsScreen> createState() => _EditSettingsScreenState();
}

class _EditSettingsScreenState extends ConsumerState<EditSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String _sex = 'Male';
  String _activity = 'Active';
  late final TextEditingController _calMin;
  late final TextEditingController _calMax;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fats;
  bool _busy = false;
  String _units = 'metric';
  bool _unitsHydrated = false;
  bool _fieldsHydrated = false;
  bool _backupBusy = false;

  @override
  void initState() {
    super.initState();
    _age = TextEditingController();
    _height = TextEditingController();
    _weight = TextEditingController();
    _calMin = TextEditingController();
    _calMax = TextEditingController();
    _protein = TextEditingController();
    _carbs = TextEditingController();
    _fats = TextEditingController();
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _calMin.dispose();
    _calMax.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // Convert to metric for storage if needed
      final heightCm = _units == 'metric' ? int.tryParse(_height.text) : _inchToCm(_height.text);
      final weightKg = _units == 'metric' ? double.tryParse(_weight.text) : _lbToKg(_weight.text);

      await ref.read(settingsRepositoryProvider).save(ProfileGoals(
            ageYears: int.tryParse(_age.text),
            heightCm: heightCm,
            weightKg: weightKg,
            gender: _sex,
            activityLevel: _activity,
            caloriesMin: int.tryParse(_calMin.text),
            caloriesMax: int.tryParse(_calMax.text),
            proteinG: int.tryParse(_protein.text),
            carbsG: int.tryParse(_carbs.text),
            fatsG: int.tryParse(_fats.text),
          ));
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetOnboarding() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset and Restart Onboarding?'),
        content: const Text('This will remove all profile and goals data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(settingsRepositoryProvider).resetAll();
    if (!mounted) return;
    context.goNamed('onboarding');
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

  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      final appSupport = await getApplicationSupportDirectory();
      final dbPath = p.join(appSupport.path, 'gymrat.db');
      final walPath = p.join(appSupport.path, 'gymrat.db-wal');
      final shmPath = p.join(appSupport.path, 'gymrat.db-shm');
      final now = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupName = 'gymrat-backup-$now.zip';

      // Simple zip: store raw files concatenated with headers (minimalist). For production use, consider archive package.
      final tempDir = await getTemporaryDirectory();
      final outFile = File(p.join(tempDir.path, backupName));
      final sink = outFile.openWrite();
      Future<void> add(String label, File f) async {
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          sink.writeln('FILE:$label:${bytes.length}');
          sink.add(bytes);
          sink.writeln();
        }
      }
      await add('gymrat.db', File(dbPath));
      await add('gymrat.db-wal', File(walPath));
      await add('gymrat.db-shm', File(shmPath));
      await sink.flush();
      await sink.close();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup created'),
          content: Text('Saved temporary backup file:\n${outFile.path}\n\nUse the system share sheet to move it to Files/iCloud.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    // Minimal placeholder: instruct user where to place replacement DB; production should use file_picker
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from file'),
        content: const Text('Restore flow requires picking a backup file. To fully implement, we will use a file picker to select the .zip created by backup and replace the DB. For now, this is a placeholder.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  String _cmToInText(int? cm) {
    if (cm == null) return '';
    return (cm / 2.54).toStringAsFixed(1);
  }

  String _kgToLbText(double? kg) {
    if (kg == null) return '';
    return (kg / 0.45359237).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final pgAsync = ref.watch(profileGoalsProvider);
    final unitsAsync = ref.watch(unitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile & Goals')),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (units) {
          if (!_unitsHydrated) {
            _units = units;
            _unitsHydrated = true;
          }
          return pgAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (pg) {
              if (!_fieldsHydrated) {
                _age.text = (pg.ageYears ?? '').toString();
                _sex = (pg.gender == 'Female') ? 'Female' : 'Male';
                _activity = pg.activityLevel ?? _activity;
                _calMin.text = (pg.caloriesMin ?? '').toString();
                _calMax.text = (pg.caloriesMax ?? '').toString();
                _protein.text = (pg.proteinG ?? '').toString();
                _carbs.text = (pg.carbsG ?? '').toString();
                _fats.text = (pg.fatsG ?? '').toString();
                // Convert display values to selected units
                _height.text = _units == 'metric' ? (pg.heightCm ?? '').toString() : _cmToInText(pg.heightCm);
                _weight.text = _units == 'metric' ? (pg.weightKg ?? '').toString() : _kgToLbText(pg.weightKg);
                _fieldsHydrated = true;
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                            // Re-convert current values for display
                            setState(() {
                              _height.text = _units == 'metric' ? (pg.heightCm ?? '').toString() : _cmToInText(pg.heightCm);
                              _weight.text = _units == 'metric' ? (pg.weightKg ?? '').toString() : _kgToLbText(pg.weightKg);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Age (years)'),
                      keyboardType: TextInputType.number,
                      controller: _age,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0 || n > 120) return 'Enter valid age';
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: _units == 'metric' ? 'Height (cm)' : 'Height (in)'),
                      keyboardType: TextInputType.number,
                      controller: _height,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Enter valid height';
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: _units == 'metric' ? 'Weight (kg)' : 'Weight (lb)'),
                      keyboardType: TextInputType.number,
                      controller: _weight,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Enter valid weight';
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(labelText: 'Sex'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (v) => setState(() => _sex = v ?? 'Male'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _activity,
                      decoration: const InputDecoration(labelText: 'Activity Level', helperText: 'Sedentary: little/no exercise • Lightly: 1-3 days/wk • Active: 3-5 days/wk • Very Active: 6-7 days/wk'),
                      items: const [
                        DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary (little/no exercise)')),
                        DropdownMenuItem(value: 'Lightly Active', child: Text('Lightly Active (1–3 days/week)')),
                        DropdownMenuItem(value: 'Active', child: Text('Active (3–5 days/week)')),
                        DropdownMenuItem(value: 'Very Active', child: Text('Very Active (6–7 days/week)')),
                      ],
                      onChanged: (v) => setState(() => _activity = v ?? 'Active'),
                    ),
                    const Divider(),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Calories Min'),
                      keyboardType: TextInputType.number,
                      controller: _calMin,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Calories Max'),
                      keyboardType: TextInputType.number,
                      controller: _calMax,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                      controller: _protein,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                      keyboardType: TextInputType.number,
                      controller: _carbs,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Fats (g)'),
                      keyboardType: TextInputType.number,
                      controller: _fats,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving...' : 'Save')),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _resetOnboarding,
                      child: const Text('Reset and Restart Onboarding'),
                    ),
                    const Divider(height: 32),
                    Text('Backup & Restore', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _backupBusy ? null : _exportBackup,
                          icon: const Icon(Icons.archive),
                          label: Text(_backupBusy ? 'Preparing…' : 'Back up to file'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _backupBusy ? null : _importBackup,
                          icon: const Icon(Icons.unarchive),
                          label: const Text('Restore from file'),
                        ),
                      ),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
