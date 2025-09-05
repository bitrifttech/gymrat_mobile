import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:app/features/food/data/food_repository.dart';
import 'package:app/features/workout/ui/templates_screen.dart';
import 'package:app/features/settings/ui/edit_settings_screen.dart';
import 'package:app/features/tasks/data/tasks_repository.dart';
import 'package:app/data/db/app_database.dart';

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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Templates', icon: Icon(Icons.article)),
            Tab(text: 'Foods', icon: Icon(Icons.restaurant)),
            Tab(text: 'Schedule', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Profile', icon: Icon(Icons.settings)),
            Tab(text: 'Tasks', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _TemplatesTab(),
          const _FoodsTab(),
          const ScheduleScreen(),
          const EditSettingsScreen(),
          const TasksManageTab(),
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
                final title = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final c = TextEditingController();
                    return AlertDialog(
                      title: const Text('New Task'),
                      content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Title')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Create')),
                      ],
                    );
                  },
                );
                if (title != null && title.isNotEmpty) {
                  await ref.read(tasksRepositoryProvider).createTask(title: title);
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
                subtitle: Wrap(
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
                trailing: IconButton(
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
    final mealTemplates = ref.watch(mealTemplatesProvider);
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
                      title: const Text('New Workout Template'),
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
              label: const Text('Add Workout Template'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final ctrl = TextEditingController();
                    return AlertDialog(
                      title: const Text('New Meal Template'),
                      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Template name')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Create')),
                      ],
                    );
                  },
                );
                if (name == null || name.isEmpty) return;
                await ref.read(foodRepositoryProvider).createMealTemplate(name);
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Add Meal Template'),
            ),
          ),
        ),
        Expanded(
          child: workoutTemplates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) return const Center(child: Text('No templates'));
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
        const Divider(height: 1),
        Expanded(
          child: mealTemplates.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) return const Center(child: Text('No meal templates'));
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final t = list[i];
                  return ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text(t.name),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await ref.read(foodRepositoryProvider).deleteMealTemplate(t.id);
                      },
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _servingCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(foodRepositoryProvider).addCustomFood(
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      servingDesc: _servingCtrl.text.trim().isEmpty ? null : _servingCtrl.text.trim(),
      calories: int.parse(_calCtrl.text),
      proteinG: int.parse(_proteinCtrl.text),
      carbsG: int.parse(_carbCtrl.text),
      fatsG: int.parse(_fatCtrl.text),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food added')));
    _formKey.currentState!.reset();
    _nameCtrl.clear();
    _brandCtrl.clear();
    _servingCtrl.clear();
    _calCtrl.clear();
    _proteinCtrl.clear();
    _carbCtrl.clear();
    _fatCtrl.clear();
  }

  Future<void> _editFoodDialog(Food food) async {
    final name = TextEditingController(text: food.name);
    final brand = TextEditingController(text: food.brand ?? '');
    final serving = TextEditingController(text: food.servingDesc ?? '');
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
        Text('Add Custom Food', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              TextFormField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand (optional)')),
              TextFormField(controller: _servingCtrl, decoration: const InputDecoration(labelText: 'Serving (e.g., 1 cup)')),
              Row(children: [
                Expanded(child: TextFormField(controller: _calCtrl, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number, validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _proteinCtrl, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number, validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _carbCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number, validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _fatCtrl, decoration: const InputDecoration(labelText: 'Fats (g)'), keyboardType: TextInputType.number, validator: (v) => (v == null || int.tryParse(v) == null) ? 'Number' : null)),
              ]),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.add), label: const Text('Add'))),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                        IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete', onPressed: () => ref.read(foodRepositoryProvider).deleteCustomFood(f.id)),
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


