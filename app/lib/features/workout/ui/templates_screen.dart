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
    final exercises = _selectedTemplateId == null
        ? null
        : ref.watch(templateExercisesProvider(_selectedTemplateId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Templates')),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _templateCtrl,
                          decoration: const InputDecoration(labelText: 'New template name'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final name = _templateCtrl.text.trim();
                          if (name.isEmpty) return;
                          final id = await ref.read(workoutRepositoryProvider).createTemplate(name);
                          setState(() => _selectedTemplateId = id);
                          _templateCtrl.clear();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: templates.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                    data: (list) {
                      if (list.isEmpty) return const Center(child: Text('No templates'));
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final t = list[i];
                          final selected = t.id == _selectedTemplateId;
                          return ListTile(
                            selected: selected,
                            leading: const Icon(Icons.article),
                            title: Text(t.name),
                            onTap: () => setState(() => _selectedTemplateId = t.id),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await ref.read(workoutRepositoryProvider).deleteTemplate(t.id);
                                if (_selectedTemplateId == t.id) setState(() => _selectedTemplateId = null);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedTemplateId == null
                ? const Center(child: Text('Select a template'))
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
                                        Text(te.exerciseName, style: Theme.of(context).textTheme.titleSmall),
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
          ),
        ],
      ),
    );
  }
}

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final schedule = ref.watch(scheduleProvider);
    final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Schedule')),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (templateList) {
          if (templateList.isEmpty) return const Center(child: Text('Create a template first'));
          return schedule.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (schedList) {
              final dayToTemplateId = {for (final s in schedList) s.dayOfWeek: s.templateId};
              return ListView.builder(
                itemCount: days.length,
                itemBuilder: (ctx, i) {
                  final dayIndex = i + 1; // 1..7
                  final current = dayToTemplateId[dayIndex];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(days[i]),
                    trailing: DropdownButton<int>(
                      value: current,
                      hint: const Text('Select template'),
                      items: [
                        for (final t in templateList) DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        await ref.read(workoutRepositoryProvider).setSchedule(dayOfWeek: dayIndex, templateId: v);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Saved')));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
