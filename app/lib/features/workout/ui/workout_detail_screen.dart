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
                tooltip: 'Restart workout',
                onPressed: () async {
                  final choice = await showDialog<bool>(
                    context: ctx,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Restart workout?'),
                      content: const Text('Keep previous values?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text('No (Clear)')),
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          child: const Text('Yes (Keep)')),
                      ],
                    ),
                  );
                  if (choice == null) return;
                  int newId;
                  if (choice) {
                    newId = await repo.restartWorkoutFrom(workoutId);
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Workout restarted (kept values)')));
                  } else {
                    newId = await repo.resetWorkoutFrom(workoutId);
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Workout reset (cleared values)')));
                  }
                  if (!ctx.mounted) return;
                  context.goNamed('workout.detail', pathParameters: {'id': newId.toString()});
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
    final targets = ref.watch(workoutTemplateTargetsProvider(workoutId));
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
                        final targetsMap = targets.maybeWhen(data: (m) => m, orElse: () => const {});
                        final t = targetsMap[ex.name];
                        final repsLabel = (t?.repsMin != null || t?.repsMax != null)
                            ? '${t?.repsMin ?? ''}${t?.repsMin != null && t?.repsMax != null ? '-' : ''}${t?.repsMax ?? ''} reps'
                            : '';
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
                            final setsTarget = t?.setsCount ?? 0;
                            final int maxRows = setsTarget > 0 ? setsTarget : ss.length;
                            final rows = <Widget>[];
                            for (int i = 1; i <= (maxRows == 0 ? 1 : maxRows); i++) {
                              final existing = ss.where((s) => s.setIndex == i).toList();
                              final TextEditingController repsCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.reps != null ? existing.first.reps!.toString() : '');
                              final TextEditingController weightCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.weight != null ? existing.first.weight!.toStringAsFixed(0) : '');
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
                                        decoration: InputDecoration(labelText: repsLabel.isEmpty ? 'Reps' : 'Reps ($repsLabel)'),
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onChanged: (_) async {
                                          final reps = int.tryParse(repsCtrl.text);
                                          final weightInt = int.tryParse(weightCtrl.text);
                                          final weight = weightInt?.toDouble();
                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                workoutExerciseId: we.id,
                                                setIndex: i,
                                                reps: reps,
                                                weight: weight,
                                              );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: weightCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: const InputDecoration(labelText: 'Weight'),
                                        onChanged: (_) async {
                                          final reps = int.tryParse(repsCtrl.text);
                                          final weightInt = int.tryParse(weightCtrl.text);
                                          final weight = weightInt?.toDouble();
                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                workoutExerciseId: we.id,
                                                setIndex: i,
                                                reps: reps,
                                                weight: weight,
                                              );
                                        },
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
    );
  }
}
