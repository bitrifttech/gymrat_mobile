import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});
  final int workoutId;

  String _formatElapsed(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(workoutRepositoryProvider);
    return FutureBuilder(
      future: repo.getWorkoutById(workoutId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final w = snap.data!;
        final started = w.startedAt;
        final finished = w.finishedAt;
        final elapsed = finished == null ? null : finished.difference(started);
        return Scaffold(
          appBar: AppBar(
            title: Text(w.name ?? 'Workout'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(26),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  finished == null ? 'In progress' : 'Total time: ${_formatElapsed(elapsed!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save changes',
                onPressed: () {
                  FocusScope.of(ctx).unfocus();
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Changes saved')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reset workout (start over)',
                onPressed: () async {
                  await repo.resetWorkoutFrom(workoutId);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Workout reset. New session started.')));
                  context.goNamed('workout.active');
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Restart (keep values)',
                onPressed: () async {
                  await repo.restartWorkoutFrom(workoutId);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Workout restarted')));
                },
              ),
            ],
          ),
          body: _WorkoutDetailBody(workoutId: workoutId),
        );
      },
    );
  }
}

class _WorkoutDetailBody extends ConsumerWidget {
  const _WorkoutDetailBody({required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(workoutExercisesProvider(workoutId));
    return exercises.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (pairs) {
        if (pairs.isEmpty) return const Center(child: Text('No exercises'));
        return ListView(
          padding: const EdgeInsets.all(12),
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
                            if (ss.isEmpty) return const Text('No sets');
                            return Column(
                              children: [
                                for (final s in ss)
                                  Row(
                                    children: [
                                      SizedBox(width: 28, child: Text('#${s.setIndex}')),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: s.reps?.toString() ?? '',
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Reps'),
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          onChanged: (val) async {
                                            final reps = int.tryParse(val);
                                            await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                  workoutExerciseId: we.id,
                                                  setIndex: s.setIndex,
                                                  reps: reps,
                                                  weight: s.weight,
                                                );
                                          },
                                          onFieldSubmitted: (val) async {
                                            final reps = int.tryParse(val);
                                            await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                  workoutExerciseId: we.id,
                                                  setIndex: s.setIndex,
                                                  reps: reps,
                                                  weight: s.weight,
                                                );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: s.weight == null ? '' : s.weight!.toStringAsFixed(0),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: const InputDecoration(labelText: 'Weight'),
                                          onChanged: (val) async {
                                            final weightInt = int.tryParse(val);
                                            final weight = weightInt?.toDouble();
                                            await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                  workoutExerciseId: we.id,
                                                  setIndex: s.setIndex,
                                                  reps: s.reps,
                                                  weight: weight,
                                                );
                                          },
                                          onFieldSubmitted: (val) async {
                                            final weightInt = int.tryParse(val);
                                            final weight = weightInt?.toDouble();
                                            await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                  workoutExerciseId: we.id,
                                                  setIndex: s.setIndex,
                                                  reps: s.reps,
                                                  weight: weight,
                                                );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            );
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
    );
  }
}
