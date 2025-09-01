import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/data/home_repository.dart';
import 'package:go_router/go_router.dart';
import 'widgets/macro_ring.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/data/workout_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestGoal = ref.watch(latestGoalProvider);
    final todayTotals = ref.watch(todayTotalsProvider);
    final scheduledTemplate = ref.watch(scheduledTemplateTodayProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymRat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.pushNamed('settings.edit'),
            tooltip: 'Edit Profile & Goals',
          ),
        ],
      ),
      body: latestGoal.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (g) {
          if (g == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No goals found'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.pushNamed('settings.edit'),
                    child: const Text('Set Profile & Goals'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Today', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              todayTotals.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (t) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      MacroRing(label: 'Calories', current: t.calories.toDouble(), target: g.caloriesMax.toDouble()),
                      MacroRing(label: 'Protein (g)', current: t.proteinG.toDouble(), target: g.proteinG.toDouble()),
                      MacroRing(label: 'Carbs (g)', current: t.carbsG.toDouble(), target: g.carbsG.toDouble()),
                      MacroRing(label: 'Fats (g)', current: t.fatsG.toDouble(), target: g.fatsG.toDouble()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(onPressed: () => context.pushNamed('food.log'), icon: const Icon(Icons.restaurant), label: const Text('Log Food')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('meals.today'), icon: const Icon(Icons.fastfood), label: const Text("Today's Meals")),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('workout.active'), icon: const Icon(Icons.play_arrow), label: const Text('Active Workout')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('workout.history'), icon: const Icon(Icons.history), label: const Text('Workout History')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('workout.templates'), icon: const Icon(Icons.article), label: const Text('Templates')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('workout.schedule'), icon: const Icon(Icons.calendar_today), label: const Text('Schedule')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('task.add'), icon: const Icon(Icons.check_circle), label: const Text('Add Task')),
                ],
              ),
              const SizedBox(height: 24),
              Text('Today’s Tasks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              scheduledTemplate.when(
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
                data: (tpl) {
                  if (tpl == null) {
                    return const ListTile(
                      leading: Icon(Icons.event_busy),
                      title: Text('No workout scheduled today'),
                    );
                  }
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text('Today’s Workout: ${tpl.name}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await ref.read(workoutRepositoryProvider).startOrResumeTodaysScheduledWorkout();
                        if (!context.mounted) return;
                        context.pushNamed('workout.active');
                      },
                      child: const Text('Start/Resume'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text('Workout', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.fitness_center),
                title: Text('No workout scheduled'),
                subtitle: Text('Schedule or start a custom workout.'),
              ),
            ],
          );
        },
      ),
    );
  }
}
