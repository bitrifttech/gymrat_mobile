import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:app/core/notifications.dart';

enum _ExitAction { cancel, discard, save }

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});
  final int workoutId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  final GlobalKey<_WorkoutDetailBodyState> _detailKey = GlobalKey<_WorkoutDetailBodyState>();

  String _formatElapsed(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  Future<_ExitAction?> _showExitDialog(BuildContext context) {
    return showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save workout progress?'),
        content: const Text('You have an active workout. Would you like to save your progress before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.discard),
            child: const Text("Don't Save"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final choice = await _showExitDialog(context);
    if (choice == null || choice == _ExitAction.cancel) {
      return false;
    }
    if (choice == _ExitAction.save) {
      await _detailKey.currentState?.saveAllEdits();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(workoutRepositoryProvider);
    final workoutId = widget.workoutId;
    return FutureBuilder(
      future: repo.getWorkoutById(workoutId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final w = snap.data!;
        final started = w.startedAt;
        final finished = w.finishedAt;
        final elapsed = finished == null ? null : finished.difference(started);
        return WillPopScope(
          onWillPop: () async {
            if (finished != null) {
              return true;
            }
            return _confirmExit(ctx);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(w.name ?? 'Workout'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(26),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: finished == null
                      ? _ElapsedTicker(startedAt: started)
                      : Text('Total time: ${_formatElapsed(elapsed!)}',
                          style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save changes',
                  onPressed: () async {
                    FocusScope.of(ctx).unfocus();
                    await _detailKey.currentState?.saveAllEdits();
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Changes saved')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Restart workout',
                  onPressed: () async {
                    final choice = await showDialog<bool>(
                      context: ctx,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Restart workout?'),
                        content: const Text('Keep previous values?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('No (Clear)'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            child: const Text('Yes (Keep)'),
                          ),
                        ],
                      ),
                    );
                    if (choice == null) return;
                    int newId;
                    if (choice) {
                      newId = await repo.restartWorkoutFrom(workoutId);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Workout restarted (kept values)')),
                      );
                    } else {
                      newId = await repo.resetWorkoutFrom(workoutId);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Workout reset (cleared values)')),
                      );
                    }
                    if (!ctx.mounted) return;
                    context.goNamed('workout.detail', pathParameters: {'id': newId.toString()});
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _WorkoutDetailBody(key: _detailKey, workoutId: workoutId),
                ),
                if (finished == null)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            FocusScope.of(ctx).unfocus();
                            await _detailKey.currentState?.saveAllEdits();
                            await repo.finishWorkout(w.id);
                            if (!ctx.mounted) return;
                            context.push('/workout/summary/${w.id}');
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Workout saved and completed')),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Save & End Workout'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutDetailBody extends ConsumerStatefulWidget {
  const _WorkoutDetailBody({super.key, required this.workoutId});
  final int workoutId;

  @override
  ConsumerState<_WorkoutDetailBody> createState() => _WorkoutDetailBodyState();
}

class _WorkoutDetailBodyState extends ConsumerState<_WorkoutDetailBody> {
  final Map<String, TextEditingController> _repsCtrls = {};
  final Map<String, TextEditingController> _weightCtrls = {};

  String _keyFor(int workoutExerciseId, int setIndex) => '${workoutExerciseId}_$setIndex';

  Future<void> saveAllEdits() async {
    for (final entry in _repsCtrls.entries) {
      final parts = entry.key.split('_');
      if (parts.length != 2) continue;
      final weId = int.tryParse(parts[0]);
      final setIndex = int.tryParse(parts[1]);
      if (weId == null || setIndex == null) continue;
      final reps = int.tryParse(entry.value.text);
      final weight = double.tryParse(_weightCtrls[entry.key]?.text ?? '');
      await ref.read(workoutRepositoryProvider).upsertSetByIndex(
            workoutExerciseId: weId,
            setIndex: setIndex,
            reps: reps,
            weight: weight,
          );
    }
  }

  Future<void> _showAddExerciseDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Exercise name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: repsCtrl,
              decoration: const InputDecoration(labelText: 'Reps (optional)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: 'Weight (optional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter an exercise name')));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    final reps = int.tryParse(repsCtrl.text);
    final weight = double.tryParse(weightCtrl.text);
    final repo = ref.read(workoutRepositoryProvider);
    final weId = await repo.addExerciseToWorkout(workoutId: widget.workoutId, exerciseName: name);
    if (reps != null || weight != null) {
      await repo.addSet(workoutExerciseId: weId, weight: weight, reps: reps);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutId = widget.workoutId;
    final exercises = ref.watch(workoutExercisesProvider(workoutId));
    final targets = ref.watch(workoutTemplateTargetsProvider(workoutId));
    return exercises.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (pairs) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _showAddExerciseDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
            if (pairs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('No exercises yet'),
              ),
            for (final (we, ex) in pairs)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center),
                          const SizedBox(width: 8),
                          Text(ex.name, style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Consumer(builder: (ctx, ref, _) {
                            final tMap = targets.maybeWhen(data: (m) => m, orElse: () => const {});
                            final tpl = tMap[ex.name];
                            final restSec = tpl?.restSeconds ?? 90;
                            return _RestButton(restSeconds: restSec, key: ValueKey('rest-${we.id}'));
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Consumer(builder: (context, ref, _) {
                        final sets = ref.watch(workoutExerciseSetsProvider(we.id));
                        final targetsMap = targets.maybeWhen(data: (m) => m, orElse: () => const {});
                        final t = targetsMap[ex.name];
                        final repsLabel = (t?.repsMin != null || t?.repsMax != null)
                            ? '${t?.repsMin ?? ''}${t?.repsMin != null && t?.repsMax != null ? '-' : ''}${t?.repsMax ?? ''} reps'
                            : '';
                        return sets.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, st) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Error: $e'),
                          ),
                          data: (ss) {
                            final setsTarget = t?.setsCount ?? 0;
                            final int maxRows = setsTarget > 0 ? setsTarget : ss.length;
                            final rows = <Widget>[];
                            for (int i = 1; i <= (maxRows == 0 ? 1 : maxRows); i++) {
                              final existing = ss.where((s) => s.setIndex == i).toList();
                              final k = _keyFor(we.id, i);
                              final repsCtrl = _repsCtrls.putIfAbsent(k, () => TextEditingController(text: existing.isNotEmpty && existing.first.reps != null ? existing.first.reps!.toString() : ''));
                              final weightCtrl = _weightCtrls.putIfAbsent(k, () => TextEditingController(text: existing.isNotEmpty && existing.first.weight != null ? existing.first.weight!.toString() : ''));
                              Future<void> saveRow() async {
                                final reps = int.tryParse(repsCtrl.text);
                                final weight = double.tryParse(weightCtrl.text);
                                await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                      workoutExerciseId: we.id,
                                      setIndex: i,
                                      reps: reps,
                                      weight: weight,
                                    );
                              }
                              rows.add(Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    SizedBox(width: 28, child: Text('#$i')),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: repsCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(labelText: repsLabel.isEmpty ? 'Reps' : 'Reps ($repsLabel)'),
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        onEditingComplete: () async { await saveRow(); },
                                        onSubmitted: (_) async { await saveRow(); },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: weightCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
                                        decoration: const InputDecoration(labelText: 'Weight'),
                                        onEditingComplete: () async { await saveRow(); },
                                        onSubmitted: (_) async { await saveRow(); },
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                            }
                            return Column(children: rows);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RestButton extends StatefulWidget {
  const _RestButton({super.key, required this.restSeconds});
  final int restSeconds;
  @override
  State<_RestButton> createState() => _RestButtonState();
}

class _RestButtonState extends State<_RestButton> with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _endAt;
  bool _notifiedDone = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    _ticker?.cancel();
    setState(() {
      _endAt = DateTime.now().add(Duration(seconds: widget.restSeconds));
      _notifiedDone = false;
    });
    // Schedule a background notification for when the rest ends
    if (_endAt != null) {
      Notifications.scheduleRestCompleteAt(_endAt!);
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      final remaining = _computeRemainingSeconds();
      if (remaining <= 0) {
        t.cancel();
        if (!_notifiedDone) {
          _notifiedDone = true;
          final hasVib = await Vibration.hasVibrator();
          if (hasVib == true) {
            Vibration.vibrate(duration: 500);
          } else {
            HapticFeedback.mediumImpact();
          }
          await Notifications.showRestComplete();
          // Clear any scheduled notification if we're in foreground
          await Notifications.cancelScheduledRest();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rest complete')));
          }
        }
        setState(() {
          _endAt = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  void _toggle() {
    final active = _endAt != null && _computeRemainingSeconds() > 0;
    if (active) {
      _ticker?.cancel();
      setState(() {
        _endAt = null;
      });
      Notifications.cancelScheduledRest();
    } else {
      _start();
    }
  }

  int _computeRemainingSeconds() {
    if (_endAt == null) return 0;
    final diff = _endAt!.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      // Force a rebuild to update remaining based on end time after resume
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _computeRemainingSeconds();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              Duration(seconds: remaining).toString().split('.').first.padLeft(8, '0'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.timer),
          label: Text(remaining > 0 ? 'Stop' : 'Rest'),
          onPressed: _toggle,
        ),
      ],
    );
  }
}

class _ElapsedTicker extends StatefulWidget {
  const _ElapsedTicker({required this.startedAt});
  final DateTime startedAt;
  @override
  State<_ElapsedTicker> createState() => _ElapsedTickerState();
}

class _ElapsedTickerState extends State<_ElapsedTicker> with WidgetsBindingObserver {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsed = now.difference(widget.startedAt);
    return Text('Elapsed: ${_formatElapsed(elapsed)}', style: Theme.of(context).textTheme.bodySmall);
  }
}
