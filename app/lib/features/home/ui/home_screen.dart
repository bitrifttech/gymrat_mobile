import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/data/home_repository.dart';
import 'package:go_router/go_router.dart';
import 'widgets/macro_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestGoal = ref.watch(latestGoalProvider);
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

          // Placeholder current values: 0 until logging implemented.
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Today', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  MacroRing(label: 'Calories', current: 0, target: g.caloriesMax.toDouble()),
                  MacroRing(label: 'Protein (g)', current: 0, target: g.proteinG.toDouble()),
                  MacroRing(label: 'Carbs (g)', current: 0, target: g.carbsG.toDouble()),
                  MacroRing(label: 'Fats (g)', current: 0, target: g.fatsG.toDouble()),
                ],
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
                  ElevatedButton.icon(onPressed: () => context.pushNamed('workout.start'), icon: const Icon(Icons.fitness_center), label: const Text('Start Workout')),
                  ElevatedButton.icon(onPressed: () => context.pushNamed('task.add'), icon: const Icon(Icons.check_circle), label: const Text('Add Task')),
                ],
              ),
              const SizedBox(height: 24),
              Text('Today’s Tasks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.check_box_outline_blank),
                title: Text('No tasks configured'),
                subtitle: Text('Tasks will appear here once added.'),
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
