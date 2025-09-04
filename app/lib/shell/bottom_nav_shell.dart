import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/workout/data/workout_repository.dart';
import 'package:app/features/workout/ui/templates_screen.dart';
import 'package:app/features/settings/ui/edit_settings_screen.dart';
import 'package:app/features/tasks/data/tasks_repository.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          const ScheduleScreen(),
          const EditSettingsScreen(),
          _NavButton(label: 'Add Task (stub)', onTap: () => context.pushNamed('task.add')),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
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
                      title: const Text('New Template'),
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
              label: const Text('Add Template'),
            ),
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


