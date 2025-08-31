import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/home/data/home_repository.dart';
import 'package:go_router/go_router.dart';

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
      body: Center(
        child: latestGoal.when(
          data: (g) {
            if (g == null) {
              return const Text('Home');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Calories: ${g.caloriesMin} - ${g.caloriesMax}')
                    .copyWithStyle(context),
                Text('Protein: ${g.proteinG} g').copyWithStyle(context),
                Text('Carbs: ${g.carbsG} g').copyWithStyle(context),
                Text('Fats: ${g.fatsG} g').copyWithStyle(context),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
        ),
      ),
    );
  }
}

extension _TextStyleExt on Text {
  Widget copyWithStyle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        data ?? '',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
