import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final _exerciseCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Workout'),
        actions: [
          active.maybeWhen(
            data: (w) => w == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.flag),
                    tooltip: 'Finish Workout',
                    onPressed: () async {
                      await ref.read(workoutRepositoryProvider).finishWorkout(w.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout finished')));
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _exerciseCtrl,
                      decoration: const InputDecoration(labelText: 'Exercise name'),
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
                    child: const Text('Add Exercise'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              exercises.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
                data: (pairs) {
                  if (pairs.isEmpty) return const Text('No exercises yet');
                  return Column(
                    children: [
                      for (final (we, ex) in pairs)
                        Card(
                          child: ExpansionTile(
                            title: Text(ex.name),
                            subtitle: Text('Sets'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _weightCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Weight'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _repsCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Reps'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final weight = double.tryParse(_weightCtrl.text);
                                        final reps = int.tryParse(_repsCtrl.text);
                                        await ref.read(workoutRepositoryProvider).addSet(
                                              workoutExerciseId: we.id,
                                              weight: weight,
                                              reps: reps,
                                            );
                                        _weightCtrl.clear();
                                        _repsCtrl.clear();
                                      },
                                      child: const Text('Add Set'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Consumer(builder: (context, ref, _) {
                                final sets = ref.watch(workoutExerciseSetsProvider(we.id));
                                return sets.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, st) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('Error: $e'),
                                  ),
                                  data: (ss) {
                                    if (ss.isEmpty) return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('No sets yet'),
                                    );
                                    return Column(
                                      children: [
                                        for (final s in ss)
                                          ListTile(
                                            leading: const Icon(Icons.fitness_center),
                                            title: Text('Set ${s.setIndex}'),
                                            subtitle: Text('Weight: ${s.weight?.toStringAsFixed(1) ?? '-'}  •  Reps: ${s.reps ?? '-'}'),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
