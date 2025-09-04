import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/features/tasks/data/tasks_repository.dart';
import 'dart:math' as math;

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

class _NutritionTab extends ConsumerStatefulWidget {
  const _NutritionTab();

  @override
  ConsumerState<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends ConsumerState<_NutritionTab> {
  String _macro = 'calories'; // calories|protein|carbs|fats|all
  String _range = 'week'; // week|month|all
  List<DailyMacroTotals> _data = const [];
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(foodRepositoryProvider);
      final now = DateTime.now();
      _end = DateTime(now.year, now.month, now.day);
      DateTime start;
      if (_range == 'week') {
        start = _end.subtract(const Duration(days: 6));
      } else if (_range == 'month') {
        start = _end.subtract(const Duration(days: 29));
      } else {
        final earliest = await repo.readEarliestMealDate() ?? _end.subtract(const Duration(days: 365));
        start = earliest;
      }
      _start = start;
      // Use per-day totals matching Meal History logic to avoid SQL grouping edge cases
      _data = await repo.readDailyMacrosByDays(start: start, end: _end);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(label: const Text('Kcal'), selected: _macro == 'calories', onSelected: (v) { setState(() => _macro = 'calories'); _load(); }),
            ChoiceChip(label: const Text('Protein'), selected: _macro == 'protein', onSelected: (v) { setState(() => _macro = 'protein'); _load(); }),
            ChoiceChip(label: const Text('Carbs'), selected: _macro == 'carbs', onSelected: (v) { setState(() => _macro = 'carbs'); _load(); }),
            ChoiceChip(label: const Text('Fats'), selected: _macro == 'fats', onSelected: (v) { setState(() => _macro = 'fats'); _load(); }),
            ChoiceChip(label: const Text('All'), selected: _macro == 'all', onSelected: (v) { setState(() => _macro = 'all'); _load(); }),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(label: const Text('Week'), selected: _range == 'week', onSelected: (v) { setState(() => _range = 'week'); _load(); }),
            FilterChip(label: const Text('Month'), selected: _range == 'month', onSelected: (v) { setState(() => _range = 'month'); _load(); }),
            FilterChip(label: const Text('All'), selected: _range == 'all', onSelected: (v) { setState(() => _range = 'all'); _load(); }),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Text('Error: $_error'),
        if (!_loading && _error == null) ...[
          _MacroChart(data: _data, macro: _macro, start: _start, end: _end),
        ],
      ],
    );
  }
}

class _MacroChart extends StatelessWidget {
  const _MacroChart({required this.data, required this.macro, required this.start, required this.end});
  final List<DailyMacroTotals> data;
  final String macro; // calories|protein|carbs|fats|all
  final DateTime start;
  final DateTime end;

  String _kLabel(double v) { if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}K'; return v.toStringAsFixed(0); }

  (double axisMax, double interval) _niceAxis(double maxVal) {
    if (maxVal <= 0) return (1, 0.25);
    final desiredTicks = 5;
    final raw = maxVal / desiredTicks;
    final exp = (raw == 0) ? 0 : (math.log(raw) / 2.302585092994046).floor(); // log10
    final mag = pow10(exp);
    final f = raw / mag;
    double step;
    if (f < 1.5) step = 1 * mag;
    else if (f < 3) step = 2 * mag;
    else if (f < 7) step = 5 * mag;
    else step = 10 * mag;
    final axisMax = (maxVal / step).ceil() * step;
    return (axisMax, step);
  }

  double pow10(int exp) {
    double r = 1;
    if (exp > 0) { for (int i = 0; i < exp; i++) { r *= 10; } }
    if (exp < 0) { for (int i = 0; i > exp; i--) { r /= 10; } }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final series = <List<FlSpot>>[];
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
    ];
    double maxY = 0;
    List<String> labels = [];

    List<double> valuesFor(DailyMacroTotals d) => switch (macro) {
      'calories' => [d.calories.toDouble()],
      'protein' => [d.proteinG.toDouble()],
      'carbs' => [d.carbsG.toDouble()],
      'fats' => [d.fatsG.toDouble()],
      _ => [d.calories.toDouble(), d.proteinG.toDouble(), d.carbsG.toDouble(), d.fatsG.toDouble()],
    };

    // Build spots
    int lines = macro == 'all' ? 4 : 1;
    for (int l = 0; l < lines; l++) { series.add([]); }
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final vals = valuesFor(d);
      for (int l = 0; l < lines; l++) {
        final v = vals[l];
        if (v > maxY) maxY = v;
        series[l].add(FlSpot(i.toDouble(), v));
      }
      labels.add('${d.date.month}/${d.date.day}');
    }

    final bars = <LineChartBarData>[];
    for (int l = 0; l < series.length; l++) {
      bars.add(LineChartBarData(
        spots: series[l],
        isCurved: true,
        barWidth: 3,
        color: colors[l % colors.length],
        dotData: const FlDotData(show: false),
      ));
    }

    final axis = _niceAxis(maxY);
    final chartMaxY = axis.$1;
    final interval = axis.$2;

    return SizedBox(
      height: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: true),
            lineBarsData: bars,
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, interval: interval, getTitlesWidget: (v, m) {
                if (v >= chartMaxY - 1e-6) return const SizedBox.shrink();
                return Text(_kLabel(v), style: const TextStyle(fontSize: 10));
              })),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Text(labels[idx], style: const TextStyle(fontSize: 10));
              })),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final idx = s.x.toInt();
                  final d = data[idx];
                  final name = switch (macro) {
                    'calories' => 'kcal',
                    'protein' => 'Protein g',
                    'carbs' => 'Carbs g',
                    'fats' => 'Fats g',
                    _ => ['kcal','P','C','F'][spots.indexOf(s)],
                  };
                  return LineTooltipItem('${d.date.month}/${d.date.day}\n${s.y.toStringAsFixed(0)} $name', const TextStyle());
                }).toList(),
              ),
            ),
            minY: 0,
            maxY: chartMaxY,
          )),
        ),
      ),
    );
  }
}

// Debug panel removed

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyVolumeProvider);
    final topEx = ref.watch(topExerciseVolumeProvider);
    final best = ref.watch(bestOneRmProvider);
    final habits7 = ref.watch(habitsLast7Provider);
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
        Text('Habits Completion (last 7 days)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        habits7.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
          data: (list) => _HabitsCompletionBarChart(list: list),
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
    double pow10(int exp) { double r = 1; if (exp > 0) { for (int i = 0; i < exp; i++) { r *= 10; } } if (exp < 0) { for (int i = 0; i > exp; i--) { r /= 10; } } return r; }
    (double axisMax, double interval) niceAxis(double maxVal) {
      if (maxVal <= 0) return (1, 0.25);
      final desiredTicks = 4;
      final raw = maxVal / desiredTicks;
      final exp = (raw == 0) ? 0 : (math.log(raw) / 2.302585092994046).floor();
      final mag = pow10(exp);
      final f = raw / mag;
      double step;
      if (f < 1.5) step = 1 * mag; else if (f < 3) step = 2 * mag; else if (f < 7) step = 5 * mag; else step = 10 * mag;
      final axisMax = (maxVal / step).ceil() * step;
      return (axisMax, step);
    }
    final axis = niceAxis(maxY);
    final chartMaxY = axis.$1;
    final interval = axis.$2;
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
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval, getTitlesWidget: (v, m) {
                  if (v >= chartMaxY - 1e-6) return const SizedBox.shrink();
                  String label; if (v >= 1000) { label = '${(v/1000).toStringAsFixed(0)}K'; } else { label = v.toStringAsFixed(0); }
                  return Text(label, style: const TextStyle(fontSize: 10));
                })),
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
              maxY: chartMaxY,
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
    double pow10(int exp) { double r = 1; if (exp > 0) { for (int i = 0; i < exp; i++) { r *= 10; } } if (exp < 0) { for (int i = 0; i > exp; i--) { r /= 10; } } return r; }
    (double axisMax, double interval) niceAxis(double maxVal) {
      if (maxVal <= 0) return (1, 0.25);
      final desiredTicks = 4;
      final raw = maxVal / desiredTicks;
      final exp = (raw == 0) ? 0 : (math.log(raw) / 2.302585092994046).floor();
      final mag = pow10(exp);
      final f = raw / mag;
      double step;
      if (f < 1.5) step = 1 * mag; else if (f < 3) step = 2 * mag; else if (f < 7) step = 5 * mag; else step = 10 * mag;
      final axisMax = (maxVal / step).ceil() * step;
      return (axisMax, step);
    }
    final axis = niceAxis(maxY);
    final chartMaxY = axis.$1;
    final interval = axis.$2;
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
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval, getTitlesWidget: (v, m) {
                  if (v >= chartMaxY - 1e-6) return const SizedBox.shrink();
                  String label; if (v >= 1000) { label = '${(v/1000).toStringAsFixed(0)}K'; } else { label = v.toStringAsFixed(0); }
                  return SizedBox(width: 40, child: Text(label, style: const TextStyle(fontSize: 10)));
                })),
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
              maxY: chartMaxY,
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitsCompletionBarChart extends StatelessWidget {
  const _HabitsCompletionBarChart({required this.list});
  final List<DailyHabitCompletion> list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.shrink();
    final bars = <BarChartGroupData>[];
    double maxY = 100;
    for (int i = 0; i < list.length; i++) {
      final v = list[i].percent.clamp(0.0, 100.0).toDouble();
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: Theme.of(context).colorScheme.tertiary, width: 16, borderRadius: BorderRadius.circular(4)),
      ]));
    }
    final labels = [for (final d in list) '${d.date.month}/${d.date.day}'];
    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: BarChart(BarChartData(
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: true),
            barGroups: bars,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 25, getTitlesWidget: _leftTitle)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Text(labels[idx], style: const TextStyle(fontSize: 10));
              })),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = list[group.x.toInt()];
                  final pct = rod.toY.clamp(0.0, 100.0).toStringAsFixed(0);
                  return BarTooltipItem('${d.date.month}/${d.date.day}\n$pct%', const TextStyle());
                },
              ),
            ),
            maxY: maxY,
            minY: 0,
          )),
        ),
      ),
    );
  }

  static Widget _leftTitle(double v, TitleMeta m) {
    if (v < 0 || v > 100) return const SizedBox.shrink();
    if (v % 25 != 0) return const SizedBox.shrink();
    return Text('${v.toInt()}%', style: const TextStyle(fontSize: 10));
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
