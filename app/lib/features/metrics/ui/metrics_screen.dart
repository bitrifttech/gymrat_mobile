import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/data/workout_repository.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Metrics'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Nutrition'),
              Tab(text: 'Workouts'),
              Tab(text: 'PRs'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _NutritionTab(),
            _WorkoutsTab(),
            _PRsTab(),
          ],
        ),
      ),
    );
  }
}

class _NutritionTab extends ConsumerWidget {
  const _NutritionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d7 = ref.watch(dailyMacros7Provider);
    final d30 = ref.watch(dailyMacros30Provider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Last 7 days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        d7.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => _DailyList(list: list),
        ),
        const SizedBox(height: 16),
        Text('Last 30 days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        d30.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => _DailyList(list: list),
        ),
      ],
    );
  }
}

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyVolumeProvider);
    final topEx = ref.watch(topExerciseVolumeProvider);
    final best = ref.watch(bestOneRmProvider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Weekly Volume (last 6 weeks)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        weekly.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => Card(
            child: Column(
              children: [
                for (final w in list)
                  ListTile(dense: true, title: Text(w.yearWeek), trailing: Text(w.tonnage.toStringAsFixed(0))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Top Exercises by Volume', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        topEx.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => Card(
            child: Column(
              children: [
                for (final e in list)
                  ListTile(dense: true, title: Text(e.exerciseName), trailing: Text(e.tonnage.toStringAsFixed(0))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Best Estimated 1RM', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        best.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => Card(
            child: Column(
              children: [
                for (final b in list)
                  ListTile(dense: true, title: Text(b.exerciseName), trailing: Text(b.oneRm.toStringAsFixed(1))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PRsTab extends StatelessWidget {
  const _PRsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('PRs coming soon'));
  }
}

class _DailyList extends StatelessWidget {
  const _DailyList({required this.list});
  final List<DailyMacroTotals> list;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final d in list)
            ListTile(
              dense: true,
              title: Text('${d.date.month}/${d.date.day}  Calories: ${d.calories}'),
              subtitle: Text('P:${d.proteinG}  C:${d.carbsG}  F:${d.fatsG}'),
            ),
        ],
      ),
    );
  }
}
