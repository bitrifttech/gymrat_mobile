import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final _exerciseCtrl = TextEditingController();
  final Map<int, Timer?> _timersByWorkoutExerciseId = {};
  final Map<int, int> _remainingSecondsByWorkoutExerciseId = {};
  final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  int? _timerWorkoutId;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _notifier.initialize(initSettings);
  }

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    for (final t in _timersByWorkoutExerciseId.values) {
      t?.cancel();
    }
    _stopElapsedTimer();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final d = Duration(seconds: seconds);
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  void _startElapsedTimer(int workoutId, DateTime startedAt) {
    if (_timerWorkoutId == workoutId && _elapsedTimer != null) return;
    _elapsedTimer?.cancel();
    _timerWorkoutId = workoutId;
    setState(() {
      _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
      });
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _timerWorkoutId = null;
  }

  Future<void> _alertRestComplete() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 150, 100, 150]);
    }
    const android = AndroidNotificationDetails(
      'rest_timer',
      'Rest Timer',
      channelDescription: 'Alerts when rest timer completes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: false);
    const details = NotificationDetails(android: android, iOS: ios);
    await _notifier.show(0, 'Rest complete', 'Time to lift!', details);
  }

  void _startRestTimer({required int workoutExerciseId, required int seconds}) {
    _timersByWorkoutExerciseId[workoutExerciseId]?.cancel();
    setState(() {
      _remainingSecondsByWorkoutExerciseId[workoutExerciseId] = seconds;
    });
    _timersByWorkoutExerciseId[workoutExerciseId] = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final current = _remainingSecondsByWorkoutExerciseId[workoutExerciseId] ?? 0;
      if (current <= 1) {
        timer.cancel();
        setState(() {
          _remainingSecondsByWorkoutExerciseId[workoutExerciseId] = 0;
        });
        await _alertRestComplete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rest complete')));
      } else {
        setState(() {
          _remainingSecondsByWorkoutExerciseId[workoutExerciseId] = current - 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Workout'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(_formatElapsed(_elapsedSeconds), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ],
      ),
      body: active.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (w) {
          if (w == null) {
            _stopElapsedTimer();
            return Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final id = await ref.read(workoutRepositoryProvider).startWorkout();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Workout started (#$id)')));
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
              ),
            );
          }

          // Start (or continue) the elapsed timer for this workout
          _startElapsedTimer(w.id, w.startedAt);

          final exercises = ref.watch(workoutExercisesProvider(w.id));
          final targets = ref.watch(workoutTemplateTargetsProvider(w.id));
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _exerciseCtrl,
                            decoration: const InputDecoration(labelText: 'Add exercise by name'),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) async {
                              final name = _exerciseCtrl.text.trim();
                              if (name.isEmpty) return;
                              await ref.read(workoutRepositoryProvider).addExerciseToWorkout(workoutId: w.id, exerciseName: name);
                              _exerciseCtrl.clear();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = _exerciseCtrl.text.trim();
                            if (name.isEmpty) return;
                            await ref.read(workoutRepositoryProvider).addExerciseToWorkout(workoutId: w.id, exerciseName: name);
                            _exerciseCtrl.clear();
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    exercises.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error: $e'),
                      data: (pairs) {
                        final targetsMap = targets.maybeWhen(data: (m) => m, orElse: () => const {});
                        if (pairs.isEmpty) return const Text('No exercises yet');
                        return Column(
                          children: [
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
                                          Expanded(child: Text(ex.name, style: Theme.of(context).textTheme.titleMedium)),
                                          Builder(builder: (ctx) {
                                            final t = targetsMap[ex.name];
                                            final restSec = t?.restSeconds ?? 90;
                                            final remaining = _remainingSecondsByWorkoutExerciseId[we.id] ?? 0;
                                            return Row(
                                              children: [
                                                if (remaining > 0)
                                                  Text('${Duration(seconds: remaining).toString().split('.').first.padLeft(8, '0')}'),
                                                const SizedBox(width: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    _startRestTimer(workoutExerciseId: we.id, seconds: restSec);
                                                  },
                                                  icon: const Icon(Icons.timer),
                                                  label: Text(remaining > 0 ? 'Restart Rest' : 'Start Rest (${restSec}s)'),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(builder: (ctx) {
                                        final t = targetsMap[ex.name];
                                        final setsTarget = t?.setsCount ?? 0;
                                        final repsLabel = (t?.repsMin != null || t?.repsMax != null)
                                            ? '${t?.repsMin ?? ''}${t?.repsMin != null && t?.repsMax != null ? '-' : ''}${t?.repsMax ?? ''} reps'
                                            : '';
                                        final existingSets = ref.watch(workoutExerciseSetsProvider(we.id));
                                        return existingSets.when(
                                          loading: () => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                          error: (e, st) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Error: $e'),
                                          ),
                                          data: (ss) {
                                            final int maxRows = setsTarget > 0 ? setsTarget : ss.length;
                                            final rows = <Widget>[];
                                            for (int i = 1; i <= (maxRows == 0 ? 1 : maxRows); i++) {
                                              final existing = ss.where((s) => s.setIndex == i).toList();
                                              final weightCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.weight != null ? existing.first.weight!.toStringAsFixed(0) : '');
                                              final repsCtrl = TextEditingController(text: existing.isNotEmpty && existing.first.reps != null ? existing.first.reps!.toString() : '');
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
                                                        textInputAction: TextInputAction.next,
                                                        decoration: InputDecoration(labelText: repsLabel.isEmpty ? 'Reps' : 'Reps ($repsLabel)'),
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onChanged: (_) async {
                                                          final reps = int.tryParse(repsCtrl.text);
                                                          final weightInt = int.tryParse(weightCtrl.text);
                                                          final weight = weightInt?.toDouble();
                                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                                workoutExerciseId: we.id,
                                                                setIndex: i,
                                                                reps: reps,
                                                                weight: weight,
                                                              );
                                                        },
                                                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: weightCtrl,
                                                        keyboardType: TextInputType.number,
                                                        textInputAction: TextInputAction.next,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        decoration: const InputDecoration(labelText: 'Weight'),
                                                        onChanged: (_) async {
                                                          final reps = int.tryParse(repsCtrl.text);
                                                          final weightInt = int.tryParse(weightCtrl.text);
                                                          final weight = weightInt?.toDouble();
                                                          await ref.read(workoutRepositoryProvider).upsertSetByIndex(
                                                                workoutExerciseId: we.id,
                                                                setIndex: i,
                                                                reps: reps,
                                                                weight: weight,
                                                              );
                                                        },
                                                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        _stopElapsedTimer();
                        await ref.read(workoutRepositoryProvider).finishWorkout(w.id);
                        if (!context.mounted) return;
                        context.goNamed('home');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout saved and completed')));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save & End Workout'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
