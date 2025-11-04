import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/ui/templates_screen.dart';
import 'package:app/features/settings/ui/edit_settings_screen.dart';
import 'package:app/features/settings/ui/about_screen.dart';
import 'package:app/features/tasks/data/tasks_repository.dart';
import 'package:app/data/db/app_database.dart';
import 'package:app/core/app_theme.dart';

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _goBranch(int index, BuildContext context) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => _goBranch(i, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Meals'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.query_stats_outlined), selectedIcon: Icon(Icons.query_stats), label: 'Metrics'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Configure'),
        ],
      ),
    );
  }
}

class ConfigureScreen extends StatefulWidget {
  const ConfigureScreen({super.key});

  @override
  State<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends State<ConfigureScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Configure'),
        gradient: AppBarGradients.all,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Workouts', icon: Icon(Icons.article)),
            Tab(text: 'Foods', icon: Icon(Icons.restaurant)),
            Tab(text: 'Tasks', icon: Icon(Icons.check_circle)),
            Tab(text: 'Schedule', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Profile', icon: Icon(Icons.settings)),
            Tab(text: 'About', icon: Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _TemplatesTab(),
          const _FoodsTab(),
          const TasksManageTab(),
          const ScheduleScreen(),
          const EditSettingsScreen(),
          const AboutScreen(),
        ],
      ),
    );
  }
}

// _NavButton removed (unused)

class TasksManageTab extends ConsumerStatefulWidget {
  const TasksManageTab({super.key});
  @override
  ConsumerState<TasksManageTab> createState() => _TasksManageTabState();
}

class _TasksManageTabState extends ConsumerState<TasksManageTab> {
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allTasksProvider);
    final assignments = ref.watch(taskAssignmentsProvider);
    return all.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (list) => assignments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (map) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final data = await showDialog<Map<String, String?>>(
                  context: context,
                  builder: (ctx) {
                    final titleCtrl = TextEditingController();
                    final notesCtrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('New Task'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                            const SizedBox(height: 8),
                            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 4),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, {'title': titleCtrl.text.trim(), 'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim()}), child: const Text('Create')),
                      ],
                    );
                  },
                );
                final title = data?['title'] ?? '';
                final notes = data?['notes'];
                if (title.isNotEmpty) {
                  await ref.read(tasksRepositoryProvider).createTask(title: title, notes: notes);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ),
          const SizedBox(height: 12),
          for (final t in list)
            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(t.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((t.notes ?? '').isNotEmpty) Text('Notes: ${t.notes}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (int d = 1; d <= 7; d++)
                          FilterChip(
                            label: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d-1]),
                            selected: (map[t.id] ?? const {}).contains(d),
                            onSelected: (sel) async {
                              if (sel) {
                                await ref.read(tasksRepositoryProvider).assignTaskToDay(taskId: t.id, dayOfWeek: d);
                              } else {
                                await ref.read(tasksRepositoryProvider).unassignTaskFromDay(taskId: t.id, dayOfWeek: d);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final data = await showDialog<Map<String, String?>>(
                          context: context,
                          builder: (ctx) {
                            final titleCtrl = TextEditingController(text: t.title);
                            final notesCtrl = TextEditingController(text: t.notes ?? '');
                            return AlertDialog(
                              title: const Text('Edit Task'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                                    const SizedBox(height: 8),
                                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 4),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, {'title': titleCtrl.text.trim(), 'notes': notesCtrl.text.trim()}), child: const Text('Save')),
                              ],
                            );
                          },
                        );
                        if (data != null && (data['title'] ?? '').isNotEmpty) {
                          final title = data['title']!.trim();
                          final notes = (data['notes']?.trim().isEmpty ?? true) ? null : data['notes']!.trim();
                          await ref.read(tasksRepositoryProvider).updateTask(taskId: t.id, title: title, notes: notes);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated')));
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete task?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ref.read(tasksRepositoryProvider).deleteTask(t.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutTemplates = ref.watch(templatesProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('New Workout'),
                      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Template name')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Create')),
                      ],
                    );
                  },
                );
                if (name == null || name.isEmpty) return;
                final id = await ref.read(workoutRepositoryProvider).createTemplate(name);
                if (!context.mounted) return;
                context.pushNamed('workout.templates', extra: {'initialTemplateId': id});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Workout'),
            ),
          ),
        ),
        Expanded(
          child: workoutTemplates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) return const Center(child: Text('No workouts'));
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final t = list[i];
                  return ListTile(
                    leading: const Icon(Icons.article),
                    title: Text(t.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.pushNamed('workout.templates', extra: {'initialTemplateId': t.id}),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await ref.read(workoutRepositoryProvider).deleteTemplate(t.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodsTab extends ConsumerStatefulWidget {
  const _FoodsTab();
  @override
  ConsumerState<_FoodsTab> createState() => _FoodsTabState();
}

class _FoodsTabState extends ConsumerState<_FoodsTab> {
  Future<void> _addFoodDialog() async {
    final name = TextEditingController();
    final brand = TextEditingController();
    final serving = TextEditingController();
    final servingQty = TextEditingController();
    String servingUnit = 'serving';
    final cal = TextEditingController();
    final p = TextEditingController();
    final c = TextEditingController();
    final f = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand')),
              TextField(controller: serving, decoration: const InputDecoration(labelText: 'Serving desc')),
              Row(children: [
                Expanded(child: TextField(controller: servingQty, decoration: const InputDecoration(labelText: 'Serving qty'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: servingUnit,
                    items: const [
                      DropdownMenuItem(value: 'serving', child: Text('serving')),
                      DropdownMenuItem(value: 'slice', child: Text('slice')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                      DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                      DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                      DropdownMenuItem(value: 'fl oz', child: Text('Fluid ounce')),
                      DropdownMenuItem(value: 'cup', child: Text('cup')),
                      DropdownMenuItem(value: 'g', child: Text('gram')),
                      DropdownMenuItem(value: 'oz', child: Text('oz')),
                    ],
                    onChanged: (v) => servingUnit = v ?? 'serving',
                    decoration: const InputDecoration(labelText: 'Serving unit'),
                  ),
                ),
              ]),
              TextField(controller: cal, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(controller: p, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(controller: c, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(controller: f, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(foodRepositoryProvider).addCustomFood(
        name: name.text.trim(),
        brand: brand.text.trim().isEmpty ? null : brand.text.trim(),
        servingDesc: serving.text.trim().isEmpty ? null : serving.text.trim(),
        servingQty: double.tryParse(servingQty.text.trim()),
        servingUnit: servingUnit,
        calories: int.tryParse(cal.text) ?? 0,
        proteinG: int.tryParse(p.text) ?? 0,
        carbsG: int.tryParse(c.text) ?? 0,
        fatsG: int.tryParse(f.text) ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food added')));
    }
  }

  Future<void> _editFoodDialog(Food food) async {
    final name = TextEditingController(text: food.name);
    final brand = TextEditingController(text: food.brand ?? '');
    final serving = TextEditingController(text: food.servingDesc ?? '');
    final servingQty = TextEditingController(text: food.servingQty?.toString() ?? '');
    String servingUnit = food.servingUnit ?? 'serving';
    final cal = TextEditingController(text: food.calories.toString());
    final p = TextEditingController(text: food.proteinG.toString());
    final c = TextEditingController(text: food.carbsG.toString());
    final f = TextEditingController(text: food.fatsG.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand')), 
              TextField(controller: serving, decoration: const InputDecoration(labelText: 'Serving desc')), 
              Row(children: [
                Expanded(child: TextField(controller: servingQty, decoration: const InputDecoration(labelText: 'Serving qty'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: servingUnit,
                    items: const [
                      DropdownMenuItem(value: 'serving', child: Text('serving')),
                      DropdownMenuItem(value: 'slice', child: Text('slice')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                      DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                      DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                      DropdownMenuItem(value: 'fl oz', child: Text('Fluid ounce')),
                      DropdownMenuItem(value: 'cup', child: Text('cup')),
                      DropdownMenuItem(value: 'g', child: Text('gram')),
                      DropdownMenuItem(value: 'oz', child: Text('oz')),
                    ],
                    onChanged: (v) => servingUnit = v ?? 'serving',
                    decoration: const InputDecoration(labelText: 'Serving unit'),
                  ),
                ),
              ]),
              TextField(controller: cal, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(controller: p, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(controller: c, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(controller: f, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(foodRepositoryProvider).updateCustomFood(
        id: food.id,
        name: name.text.trim(),
        brand: brand.text.trim(),
        servingDesc: serving.text.trim(),
        servingQty: double.tryParse(servingQty.text.trim()),
        servingUnit: servingUnit,
        calories: int.tryParse(cal.text),
        proteinG: int.tryParse(p.text),
        carbsG: int.tryParse(c.text),
        fatsG: int.tryParse(f.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(customFoodsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addFoodDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Food'),
          ),
        ),
        const SizedBox(height: 12),
        Text('My Custom Foods', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        foods.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
          error: (e, st) => Text('Error: $e'),
          data: (list) {
            if (list.isEmpty) return const Text('No custom foods yet');
            return Column(
              children: [
                for (final f in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: Text(f.name),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if ((f.brand ?? '').isNotEmpty || (f.servingDesc ?? '').isNotEmpty) Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                        Text('P ${f.proteinG}g • C ${f.carbsG}g • F ${f.fatsG}g  •  ${f.calories} kcal'),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit), tooltip: 'Edit', onPressed: () => _editFoodDialog(f)),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete food?'),
                                content: Text('Remove "${f.name}" from your custom foods?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ref.read(foodRepositoryProvider).deleteCustomFood(f.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food deleted')));
                            }
                          },
                        ),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}


