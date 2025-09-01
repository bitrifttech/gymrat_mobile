import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final _templateCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  int? _selectedTemplateId;

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
                                return ListTile(
                                  leading: const Icon(Icons.fitness_center),
                                  title: Text(te.exerciseName),
                                  trailing: Text('#${te.orderIndex}'),
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
    final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Schedule')),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Create a template first'));
          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final dayIndex = i + 1; // 1..7
              int? selectedTemplateId;
              return ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(days[i]),
                trailing: DropdownButton<int>(
                  value: selectedTemplateId,
                  hint: const Text('Select template'),
                  items: [
                    for (final t in list) DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    await ref.read(workoutRepositoryProvider).setSchedule(dayOfWeek: dayIndex, templateId: v);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Saved')));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
