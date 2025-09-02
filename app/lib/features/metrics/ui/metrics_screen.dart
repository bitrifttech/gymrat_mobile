import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:fl_chart/fl_chart.dart';

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
          data: (list) => _CaloriesLineChart(list: list),
        ),
        const SizedBox(height: 16),
        Text('Last 30 days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        d30.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => _CaloriesLineChart(list: list),
        ),
      ],
    );
  }
}

class _CaloriesLineChart extends StatelessWidget {
  const _CaloriesLineChart({required this.list});
  final List<DailyMacroTotals> list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < list.length; i++) {
      final v = list[i].calories.toDouble();
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }
    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                  dotData: const FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox.shrink();
                      final d = list[idx].date;
                      return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => touchedSpots
                      .map((s) => LineTooltipItem('${list[s.x.toInt()].date.month}/${list[s.x.toInt()].date.day}\n${s.y.toStringAsFixed(0)} kcal', const TextStyle()))
                      .toList(),
                ),
              ),
              minY: 0,
              maxY: (maxY * 1.2).clamp(1, double.infinity),
            ),
          ),
        ),
      ),
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
          data: (list) => _WeeklyVolumeBarChart(list: list),
        ),
        const SizedBox(height: 16),
        Text('Top Exercises by Volume', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        topEx.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => _TopExercisesBarChart(list: list),
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
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(b.exerciseName),
                    trailing: Text(b.oneRm.toStringAsFixed(1)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyVolumeBarChart extends StatelessWidget {
  const _WeeklyVolumeBarChart({required this.list});
  final List<WeeklyVolume> list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.shrink();
    final bars = <BarChartGroupData>[];
    double maxY = 0;
    for (int i = 0; i < list.length; i++) {
      final v = list[i].tonnage;
      if (v > maxY) maxY = v;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: Theme.of(context).colorScheme.primary, width: 16, borderRadius: BorderRadius.circular(4)),
      ]));
    }
    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              barGroups: bars,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox.shrink();
                      return Text(list[idx].yearWeek.split('-').last, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    'Week ${list[group.x.toInt()].yearWeek.split('-').last}\n${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(),
                  ),
                ),
              ),
              maxY: (maxY * 1.2).clamp(1, double.infinity),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopExercisesBarChart extends StatelessWidget {
  const _TopExercisesBarChart({required this.list});
  final List<ExerciseVolume> list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.shrink();
    final bars = <BarChartGroupData>[];
    double maxY = 0;
    for (int i = 0; i < list.length; i++) {
      final v = list[i].tonnage;
      if (v > maxY) maxY = v;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: Theme.of(context).colorScheme.secondary, width: 16, borderRadius: BorderRadius.circular(4)),
      ]));
    }
    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              barGroups: bars,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox.shrink();
                      final name = list[idx].exerciseName;
                      return SizedBox(width: 60, child: Text(name, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis));
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${list[group.x.toInt()].exerciseName}\n${rod.toY.toStringAsFixed(0)}',
                    const TextStyle(),
                  ),
                ),
              ),
              maxY: (maxY * 1.2).clamp(1, double.infinity),
            ),
          ),
        ),
      ),
    );
  }
}

class _PRsTab extends ConsumerWidget {
  const _PRsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs = ref.watch(recentPrsProvider);
    return prs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (list) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (list.isEmpty) const Text('No PRs detected yet')
          else ...[
            for (final pr in list)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text(pr.exerciseName),
                  subtitle: Text('${pr.date.month}/${pr.date.day}'),
                  trailing: Text(pr.oneRm.toStringAsFixed(1)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
