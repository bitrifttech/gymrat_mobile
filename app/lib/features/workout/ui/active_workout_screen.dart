import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final _exerciseCtrl = TextEditingController();

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Workout'),
      ),
      body: active.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (w) {
          if (w == null) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final id = await ref.read(workoutRepositoryProvider).startWorkout();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Workout started (#$id)')));
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
              ),
            );
          }

          final exercises = ref.watch(workoutExercisesProvider(w.id));
          final targets = ref.watch(workoutTemplateTargetsProvider(w.id));
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _exerciseCtrl,
                            decoration: const InputDecoration(labelText: 'Add exercise by name'),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) async {
                              final name = _exerciseCtrl.text.trim();
                              if (name.isEmpty) return;
                              await ref.read(workoutRepositoryProvider).addExerciseToWorkout(workoutId: w.id, exerciseName: name);
                              _exerciseCtrl.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = _exerciseCtrl.text.trim();
                            if (name.isEmpty) return;
                            await ref.read(workoutRepositoryProvider).addExerciseToWorkout(workoutId: w.id, exerciseName: name);
                            _exerciseCtrl.clear();
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    exercises.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error: $e'),
                      data: (pairs) {
                        final targetsMap = targets.maybeWhen(data: (m) => m, orElse: () => const {});
                        if (pairs.isEmpty) return const Text('No exercises yet');
                        return Column(
                          children: [
                            for (final (we, ex) in pairs)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.fitness_center),
                                          const SizedBox(width: 8),
                                          Text(ex.name, style: Theme.of(context).textTheme.titleMedium),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(builder: (ctx) {
                                        final t = targetsMap[ex.name];
                                        final setsTarget = t?.setsCount ?? 0;
                                        final repsLabel = (t?.repsMin != null || t?.repsMax != null)
                                            ? '${t?.repsMin ?? ''}${t?.repsMin != null && t?.repsMax != null ? '-' : ''}${t?.repsMax ?? ''} reps'
                                            : '';
                                        final existingSets = ref.watch(workoutExerciseSetsProvider(we.id));
                                        return existingSets.when(
                                          loading: () => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                          error: (e, st) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Error: $e'),
                                          ),
                                          data: (ss) {
                                            final int maxRows = setsTarget > 0 ? setsTarget : ss.length;
                                            final rows = <Widget>[];
                                            for (int i = 1; i <= (maxRows == 0 ? 1 : maxRows); i++) {
                                              final existing = ss.where((s) => s.setIndex == i).toList();
                                              final weightCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.weight != null ? existing.first.weight!.toStringAsFixed(1) : '');
                                              final repsCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.reps != null ? existing.first.reps!.toString() : '');
                                              rows.add(Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 28, child: Text('#$i')),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: repsCtrl,
                                                        keyboardType: TextInputType.number,
                                                        textInputAction: TextInputAction.next,
                                                        decoration: InputDecoration(labelText: repsLabel.isEmpty ? 'Reps' : 'Reps ($repsLabel)'),
                                                        onChanged: (_) async {
                                                          final reps = int.tryParse(repsCtrl.text);
                                                          final weight = double.tryParse(weightCtrl.text);
                                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                                workoutExerciseId: we.id,
                                                                setIndex: i,
                                                                reps: reps,
                                                                weight: weight,
                                                              );
                                                        },
                                                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: weightCtrl,
                                                        keyboardType: TextInputType.number,
                                                        textInputAction: TextInputAction.next,
                                                        decoration: const InputDecoration(labelText: 'Weight'),
                                                        onChanged: (_) async {
                                                          final reps = int.tryParse(repsCtrl.text);
                                                          final weight = double.tryParse(weightCtrl.text);
                                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                                workoutExerciseId: we.id,
                                                                setIndex: i,
                                                                reps: reps,
                                                                weight: weight,
                                                              );
                                                        },
                                                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ));
                                            }
                                            return Column(children: rows);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await ref.read(workoutRepositoryProvider).finishWorkout(w.id);
                        if (!context.mounted) return;
                        context.goNamed('home');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout saved and completed')));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save & End Workout'),
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
