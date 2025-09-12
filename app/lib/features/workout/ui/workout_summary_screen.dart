import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(workoutSummaryProvider(workoutId));
    final prs = ref.watch(recentPrsProvider);
    final deltas = ref.watch(exerciseDeltasForWorkoutProvider(workoutId));
    final workoutPrs = ref.watch(workoutPrsForWorkoutProvider(workoutId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () async {
              final repo = ref.read(workoutRepositoryProvider);
              final s = await repo.readWorkoutSummary(workoutId);
              if (s == null) return;
              final d = await repo.readExerciseDeltasForWorkout(workoutId);
              final prsNow = await repo.readPrsForWorkout(workoutId);
              final b = StringBuffer();
              b.writeln('Workout: ${s.workout.name ?? 'Workout'}');
              b.writeln('Total sets: ${s.totalSets}');
              b.writeln('Total tonnage: ${s.totalTonnage.toStringAsFixed(0)}');
              b.writeln('');
              b.writeln('By Exercise:');
              for (final e in s.exercises) {
                final delta = d.firstWhere(
                  (x) => x.exerciseName == e.exerciseName,
                  orElse: () => WorkoutExerciseDelta(exerciseName: e.exerciseName, tonnage: e.tonnage, previousTonnage: 0),
                );
                final sign = delta.delta > 0 ? '+' : '';
                b.writeln('• ${e.exerciseName}: ${e.tonnage.toStringAsFixed(0)} (${sign}${delta.delta.toStringAsFixed(0)} vs last)');
              }
              if (prsNow.isNotEmpty) {
                b.writeln('');
                b.writeln('PRs Hit:');
                for (final p in prsNow) {
                  final sign = p.delta > 0 ? '+' : '';
                  b.writeln('• ${p.exerciseName}: ${p.oneRm.toStringAsFixed(1)} 1RM (${sign}${p.delta.toStringAsFixed(1)})');
                }
              }
              await Share.share(b.toString());
            },
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          summary.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (s) {
              if (s == null) return const Text('No summary');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.workout.name ?? 'Workout', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Total sets: ${s.totalSets}'),
                      Text('Total tonnage: ${s.totalTonnage.toStringAsFixed(0)}'),
                      const Divider(),
                      Text('By Exercise', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      deltas.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (dd) {
                          final map = {for (final d in dd) d.exerciseName: d};
                          return Column(
                            children: [
                              for (final e in s.exercises)
                                ListTile(
                                  dense: true,
                                  title: Text(e.exerciseName),
                                  subtitle: Text('Sets: ${e.setsCount}'),
                                  trailing: () {
                                    final d = map[e.exerciseName];
                                    if (d == null) return Text(e.tonnage.toStringAsFixed(0));
                                    final delta = d.delta;
                                    final sign = delta > 0 ? '+' : '';
                                    final color = delta > 0 ? Colors.green : (delta < 0 ? Colors.red : null);
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(e.tonnage.toStringAsFixed(0)),
                                        Text(' ${sign}${delta.toStringAsFixed(0)} vs last', style: TextStyle(fontSize: 12, color: color)),
                                      ],
                                    );
                                  }(),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('PRs This Workout', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          workoutPrs.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('No PRs hit this workout');
              return Card(
                child: Column(
                  children: [
                    for (final pr in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: Text(pr.exerciseName),
                        subtitle: Text('Prev: ${pr.previousBest.toStringAsFixed(1)}'),
                        trailing: Text('${pr.oneRm.toStringAsFixed(1)} 1RM'),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Recent PRs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          prs.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('No PRs in the last week');
              return Card(
                child: Column(
                  children: [
                    for (final pr in list)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: Text(pr.exerciseName),
                        trailing: Text(pr.oneRm.toStringAsFixed(1)),
                        subtitle: Text('${pr.date.month}/${pr.date.day}'),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/workout/detail/$workoutId'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Workout'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.goNamed('metrics'),
                  icon: const Icon(Icons.query_stats),
                  label: const Text('View Metrics'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
