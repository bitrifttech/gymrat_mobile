import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key, this.initialTemplateId});
  final int? initialTemplateId;

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final _templateCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  int? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = widget.initialTemplateId;
  }

  @override
  void dispose() {
    _templateCtrl.dispose();
    _exerciseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider);
    final exercises = _selectedTemplateId == null ? null : ref.watch(templateExercisesProvider(_selectedTemplateId!));

    return Scaffold(
      appBar: AppBar(
        title: templates.when(
          loading: () => const Text('Edit Template'),
          error: (e, st) => const Text('Edit Template'),
          data: (list) {
            String? name;
            if (_selectedTemplateId != null) {
              final match = list.where((t) => t.id == _selectedTemplateId).toList();
              if (match.isNotEmpty) name = match.first.name;
            }
            name ??= list.isNotEmpty ? list.first.name : null;
            return Text(name == null ? 'Edit Template' : 'Edit Template – $name');
          },
        ),
        actions: [
          if (_selectedTemplateId != null)
            IconButton(
              tooltip: 'Rename Template',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final currentName = await ref.read(workoutRepositoryProvider).watchTemplates().first.then((list) {
                  final m = list.where((t) => t.id == _selectedTemplateId).toList();
                  return m.isNotEmpty ? m.first.name : '';
                });
                final newName = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final c = TextEditingController(text: currentName);
                    return AlertDialog(
                      title: const Text('Rename Template'),
                      content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Name')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
                      ],
                    );
                  },
                );
                if (newName != null && newName.isNotEmpty) {
                  await ref.read(workoutRepositoryProvider).renameTemplate(templateId: _selectedTemplateId!, name: newName);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renamed')));
                }
              },
            ),
          if (_selectedTemplateId != null)
            IconButton(
              tooltip: 'Delete Template',
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete template?'),
                    content: const Text('This cannot be undone'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(workoutRepositoryProvider).deleteTemplate(_selectedTemplateId!);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: _selectedTemplateId == null
          ? const Center(child: Text('No template selected'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _exerciseCtrl,
                          decoration: const InputDecoration(labelText: 'Add exercise to template'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _exerciseCtrl.text.trim();
                          if (name.isEmpty) return;
                          await ref.read(workoutRepositoryProvider).addTemplateExercise(
                                templateId: _selectedTemplateId!,
                                exerciseName: name,
                              );
                          _exerciseCtrl.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: exercises!.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                    data: (list) {
                      if (list.isEmpty) return const Center(child: Text('No exercises'));
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final te = list[i];
                          final setsCtrl = TextEditingController(text: te.setsCount.toString());
                          final repsMinCtrl = TextEditingController(text: te.repsMin?.toString() ?? '');
                          final repsMaxCtrl = TextEditingController(text: te.repsMax?.toString() ?? '');
                          final restCtrl = TextEditingController(text: te.restSeconds.toString());
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: te.exerciseName,
                                          decoration: const InputDecoration(labelText: 'Exercise name'),
                                          onChanged: (val) async {
                                            final v = val.trim();
                                            if (v.isEmpty) return;
                                            await ref.read(workoutRepositoryProvider).renameTemplateExercise(templateExerciseId: te.id, name: v);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await ref.read(workoutRepositoryProvider).deleteTemplateExercise(te.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: setsCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Sets'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: repsMinCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Reps min'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: repsMaxCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Reps max'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: restCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Rest (seconds)'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final sets = int.tryParse(setsCtrl.text) ?? 3;
                                          final rmin = repsMinCtrl.text.trim().isEmpty ? null : int.tryParse(repsMinCtrl.text.trim());
                                          final rmax = repsMaxCtrl.text.trim().isEmpty ? null : int.tryParse(repsMaxCtrl.text.trim());
                                          final rest = restCtrl.text.trim().isEmpty ? null : int.tryParse(restCtrl.text.trim());
                                          await ref.read(workoutRepositoryProvider).updateTemplateExerciseTargets(
                                                templateExerciseId: te.id,
                                                setsCount: sets,
                                                repsMin: rmin,
                                                repsMax: rmax,
                                                restSeconds: rest,
                                              );
                                          if (!ctx.mounted) return;
                                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Saved')));
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDay = DateTime.now().weekday; // 1..7
  final Map<int, List<String>> _tasksByDay = {for (int d = 1; d <= 7; d++) d: <String>[]};

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider);
    final schedule = ref.watch(scheduleProvider);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (templateList) {
          return schedule.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (schedList) {
              final dayToTemplateId = {for (final s in schedList) s.dayOfWeek: s.templateId};
              final currentTplId = dayToTemplateId[_selectedDay];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Day selector
                  Center(
                    child: SegmentedButton<int>(
                      segments: [
                        for (int i = 0; i < 7; i++)
                          ButtonSegment<int>(value: i + 1, label: Text(days[i]))
                      ],
                      selected: {_selectedDay},
                      onSelectionChanged: (s) => setState(() => _selectedDay = s.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Workout', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: currentTplId,
                          hint: const Text('Select workout template'),
                          items: [
                            for (final t in templateList) DropdownMenuItem(value: t.id, child: Text(t.name)),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            await ref.read(workoutRepositoryProvider).setSchedule(dayOfWeek: _selectedDay, templateId: v);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: currentTplId == null
                            ? null
                            : () async {
                                await ref.read(workoutRepositoryProvider).clearScheduleForDay(_selectedDay);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared')));
                              },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < (_tasksByDay[_selectedDay]?.length ?? 0); i++)
                          ListTile(
                            leading: const Icon(Icons.checklist),
                            title: Text(_tasksByDay[_selectedDay]![i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() => _tasksByDay[_selectedDay]!.removeAt(i)),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Task'),
                          onTap: () async {
                            final title = await showDialog<String>(
                              context: context,
                              builder: (ctx) {
                                final c = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Add Task'),
                                  content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Title')),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Add')),
                                  ],
                                );
                              },
                            );
                            if (title != null && title.isNotEmpty) {
                              setState(() => _tasksByDay[_selectedDay]!.add(title));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy this day to...'),
                          onPressed: () async {
                            final selected = <int>{};
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return StatefulBuilder(builder: (ctx, setSt) {
                                  return AlertDialog(
                                    title: const Text('Copy to days'),
                                    content: SizedBox(
                                      width: 300,
                                      child: Wrap(
                                        spacing: 8,
                                        children: [
                                          for (int d = 1; d <= 7; d++)
                                            FilterChip(
                                              label: Text(days[d - 1]),
                                              selected: selected.contains(d),
                                              onSelected: (v) => setSt(() => v ? selected.add(d) : selected.remove(d)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Copy')),
                                    ],
                                  );
                                });
                              },
                            );
                            if (result == true) {
                              // Copy workout template assignment
                              final tplId = dayToTemplateId[_selectedDay];
                              if (tplId != null) {
                                for (final d in selected) {
                                  if (d == _selectedDay) continue;
                                  await ref.read(workoutRepositoryProvider).setSchedule(dayOfWeek: d, templateId: tplId);
                                }
                              }
                              // Copy tasks (local only)
                              final tasks = List<String>.from(_tasksByDay[_selectedDay] ?? []);
                              setState(() {
                                for (final d in selected) {
                                  if (d == _selectedDay) continue;
                                  _tasksByDay[d] = List<String>.from(tasks);
                                }
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear day'),
                        onPressed: () async {
                          await ref.read(workoutRepositoryProvider).clearScheduleForDay(_selectedDay);
                          setState(() => _tasksByDay[_selectedDay] = <String>[]);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Day cleared')));
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
