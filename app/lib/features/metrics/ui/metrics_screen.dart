import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';

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
            Center(child: Text('Workout metrics coming soon')),
            Center(child: Text('Personal records coming soon')),
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
