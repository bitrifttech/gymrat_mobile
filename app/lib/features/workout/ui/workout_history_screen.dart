import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/app_theme.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    return Scaffold(
      appBar: const GradientAppBar(
        title: Text('Workout History'),
        gradient: AppBarGradients.all,
      ),
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
                trailing: IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/workout/detail/${w.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
