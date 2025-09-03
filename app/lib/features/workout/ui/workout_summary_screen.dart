import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(workoutSummaryProvider(workoutId));
    final prs = ref.watch(recentPrsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        actions: [
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
                      for (final e in s.exercises)
                        ListTile(
                          dense: true,
                          title: Text(e.exerciseName),
                          subtitle: Text('Sets: ${e.setsCount}'),
                          trailing: Text(e.tonnage.toStringAsFixed(0)),
                        ),
                    ],
                  ),
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
                  onPressed: () => context.pushNamed('metrics'),
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
