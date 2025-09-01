import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    final repo = ref.read(workoutRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No completed workouts yet'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final w = list[i];
              final started = w.startedAt;
              final finished = w.finishedAt;
              final title = w.name ?? 'Workout';
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(title),
                subtitle: Text('${started.toLocal()} → ${finished?.toLocal() ?? ''}'),
                onTap: () => context.push('/workout/detail/${w.id}'),
                trailing: TextButton(
                  onPressed: () async {
                    await repo.restartWorkoutFrom(w.id);
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Workout restarted as active')));
                  },
                  child: const Text('Restart'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
