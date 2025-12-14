import 'package:flutter/material.dart';
import 'package:app/features/home/data/home_repository.dart';
import 'package:go_router/go_router.dart';
import 'widgets/macro_ring.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:app/features/tasks/data/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/router/route_observer.dart';
import 'package:app/core/day_change_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  DateTime? _lastKnownDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh date-scoped data when returning to dashboard
    final now = DateTime.now();
    final selectedDate = ref.read(_selectedDateProvider) ?? DateTime(now.year, now.month, now.day);
    ref.invalidate(scheduledTemplateOnDateProvider(selectedDate));
    ref.invalidate(workoutAnyOnDateProvider(selectedDate));
    ref.invalidate(totalsForDateProvider(selectedDate));
    ref.invalidate(mealsForDateProvider(selectedDate));
    ref.invalidate(totalsForDateProvider(selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final latestGoal = ref.watch(latestGoalProvider);
    final currentDate = ref.watch(currentDateProvider);
    
    // Reset to today when day changes
    if (_lastKnownDate != null && _lastKnownDate != currentDate) {
      final selectedDateState = ref.read(_selectedDateProvider);
      if (selectedDateState != null && selectedDateState.isBefore(currentDate)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(_selectedDateProvider.notifier).state = null;
        });
      }
    }
    _lastKnownDate = currentDate;
    
    final selectedDateState = ref.watch(_selectedDateProvider);
    final selectedDate = selectedDateState ?? currentDate;
    // Show totals for the selected date
    final totalsForSelected = ref.watch(totalsForDateProvider(selectedDate));
    // Date-scoped workout/task providers
    final scheduledTemplate = ref.watch(scheduledTemplateOnDateProvider(selectedDate));
    final todaysWorkoutAny = ref.watch(workoutAnyOnDateProvider(selectedDate));
    // Completion is only meaningful for today; for other days we show latest workout that day if any
    final isCompletedToday = ref.watch(todaysScheduledWorkoutCompletedProvider);
    final todaysScheduledWorkoutAny = ref.watch(todaysScheduledWorkoutAnyProvider);
    final prevDate = selectedDate.subtract(const Duration(days: 1));
    final prevMeals = ref.watch(mealsForDateProvider(prevDate));
    final prevWorkout = ref.watch(workoutAnyOnDateProvider(prevDate));
    final prevHasEntries = (prevMeals.maybeWhen(data: (list) => list.isNotEmpty, orElse: () => false))
        || (prevWorkout.maybeWhen(data: (w) => w != null, orElse: () => false));
    final canGoNext = selectedDate.isBefore(currentDate);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              icon: const Icon(Icons.chevron_left),
              onPressed: prevHasEntries
                  ? () {
                      final prev = selectedDate.subtract(const Duration(days: 1));
                      ref.read(_selectedDateProvider.notifier).state = prev;
                    }
                  : null,
            ),
            Expanded(
              child: Center(child: Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}')),
            ),
            IconButton(
              tooltip: 'Next day',
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext
                  ? () {
                      final next = selectedDate.add(const Duration(days: 1));
                      ref.read(_selectedDateProvider.notifier).state = next;
                    }
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: selectedDate.isAtSameMomentAs(currentDate)
                ? null
                : () {
                    ref.read(_selectedDateProvider.notifier).state = currentDate;
                  },
            child: const Text('Today'),
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
              Text('Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              totalsForSelected.when(
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
                  ElevatedButton.icon(
                    onPressed: () {
                      final ds = '${selectedDate.year.toString().padLeft(4,'0')}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}';
                      context.push('/food/log?date='+ds);
                    },
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Log Food'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final ds = '${selectedDate.year.toString().padLeft(4,'0')}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}';
                      context.push('/meals/by-date?date='+ds);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Meals'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Consumer(builder: (context, ref, _) {
                final dow = selectedDate.weekday; // 1..7
                final tasksToday = ref.watch(tasksForDayProvider(dow));
                final completed = ref.watch(completedOnDateProvider(selectedDate));
                return tasksToday.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (list) {
                    if (list.isEmpty) return const SizedBox.shrink();
                    return completed.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (done) => Card(
                        child: Column(
                          children: [
                            for (final t in list)
                              CheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: done.contains(t.id),
                                title: Text(
                                  t.title,
                                  style: done.contains(t.id)
                                      ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                                      : null,
                                ),
                                secondary: (t.notes ?? '').isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Notes',
                                        icon: const Icon(Icons.notes),
                                        onPressed: () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Notes'),
                                              content: Text(t.notes ?? ''),
                                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                            ),
                                          );
                                        },
                                      ),
                                onChanged: (v) async {
                                  if (v == true) {
                                    await ref.read(tasksRepositoryProvider).markTaskDoneForDate(taskId: t.id, date: selectedDate);
                                  } else {
                                    await ref.read(tasksRepositoryProvider).unmarkTaskDoneForDate(taskId: t.id, date: selectedDate);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              // Workout section reflects selected date; completion chip only for today
              isCompletedToday.when(
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
                data: (completed) {
                  if (selectedDate.isAtSameMomentAs(currentDate) && completed) {
                    return todaysWorkoutAny.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (tw) {
                        if (tw == null) {
                          return const ListTile(
                            leading: Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Today’s Workout: Completed'),
                          );
                        }
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Today’s Workout: ${tw.name ?? 'Workout'} (Completed)'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.push('/workout/detail/${tw.id}'),
                              ),
                              todaysScheduledWorkoutAny.when(
                                loading: () => const SizedBox.shrink(),
                                error: (e, st) => const SizedBox.shrink(),
                                data: (sw) => IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: sw == null
                                      ? null
                                      : () async {
                                          await ref.read(workoutRepositoryProvider).deleteTodaysScheduledWorkouts();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout deleted')));
                                        },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // For other dates, show any workout logged that day, else scheduled template if same day
                  return todaysWorkoutAny.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (wk) {
                      if (wk != null) {
                        final isCompleted = wk.finishedAt != null;
                        return ListTile(
                          leading: Icon(
                            isCompleted ? Icons.check_circle : Icons.play_circle_fill,
                            color: isCompleted ? Colors.green : null,
                          ),
                          title: Text('Workout: ${wk.name ?? 'Workout'}${isCompleted ? ' (Completed)' : ''}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(onPressed: () => context.push('/workout/detail/${wk.id}'), child: const Text('Edit')),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref.read(workoutRepositoryProvider).deleteWorkout(wk.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout deleted')));
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return scheduledTemplate.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (tpl) {
                          if (tpl == null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ListTile(
                                  leading: Icon(Icons.event_busy),
                                  title: Text('No workout scheduled'),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Make up missed workout'),
                                    onPressed: () async {
                                      await _showMakeUpWorkoutSheet(context, ref, selectedDate);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text('Scheduled Workout: ${tpl.name}'),
                            trailing: ElevatedButton(
                              onPressed: selectedDate.isAtSameMomentAs(currentDate)
                                  ? () async {
                                      final wkId = await ref.read(workoutRepositoryProvider).startOrResumeTodaysScheduledWorkout();
                                      if (!context.mounted) return;
                                      if (wkId != null) context.push('/workout/detail/$wkId');
                                    }
                                  : null,
                              child: const Text('Start'),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

final _selectedDateProvider = StateProvider<DateTime?>((ref) => null);

Future<void> _showMakeUpWorkoutSheet(BuildContext context, WidgetRef ref, DateTime selectedDate) async {
  final missed = await ref.read(workoutRepositoryProvider).readMissedScheduledWorkouts(daysBack: 14);
  final templates = await ref.read(workoutRepositoryProvider).watchTemplates().first;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Missed workouts (last 14 days)'),
            ),
            if (missed.isEmpty)
              const ListTile(title: Text('No missed workouts found'))
            else ...[
              for (final (date, tpl) in missed)
                ListTile(
                  leading: const Icon(Icons.replay),
                  title: Text('${date.month}/${date.day}/${date.year} — ${tpl.name}'),
                  onTap: () async {
                    final wkId = await ref.read(workoutRepositoryProvider).startWorkoutFromTemplateOnDate(templateId: tpl.id, date: selectedDate);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    context.push('/workout/detail/$wkId');
                  },
                ),
            ],
            const Divider(),
            const ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Choose any workout template'),
            ),
            for (final tpl in templates)
              ListTile(
                leading: const Icon(Icons.article),
                title: Text(tpl.name),
                onTap: () async {
                  final wkId = await ref.read(workoutRepositoryProvider).startWorkoutFromTemplateOnDate(templateId: tpl.id, date: selectedDate);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  context.push('/workout/detail/$wkId');
                },
              ),
          ],
        ),
      );
    },
  );
}
