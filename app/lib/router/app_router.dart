import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:app/features/home/ui/home_screen.dart';
import 'package:app/features/onboarding/ui/launch_screen.dart';
import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/features/settings/ui/edit_settings_screen.dart';
import 'package:app/features/food/ui/food_log_screen.dart';
import 'package:app/features/food/ui/meals_today_screen.dart';
import 'package:app/features/food/ui/scan_food_screen.dart';
import 'package:app/features/food/ui/food_search_screen.dart';
import 'package:app/features/workout/ui/workout_history_screen.dart';
import 'package:app/features/workout/ui/templates_screen.dart';
import 'package:app/features/workout/ui/workout_detail_screen.dart';
import 'package:app/features/metrics/ui/metrics_screen.dart';
import 'package:app/features/workout/ui/workout_summary_screen.dart';
import 'package:app/features/food/ui/meal_history_screen.dart';
import 'package:app/features/food/ui/meals_at_date_screen.dart';
import 'package:app/shell/bottom_nav_shell.dart';

class _StubScreen extends StatelessWidget {
  const _StubScreen(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/launch',
    routes: <RouteBase>[
      GoRoute(
        path: '/launch',
        name: 'launch',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const LaunchScreen());
        },
      ),
      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              name: 'home',
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meals/history',
              name: 'meals.history',
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const MealHistoryScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/workout/history',
              name: 'workout.history',
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const WorkoutHistoryScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/metrics',
              name: 'metrics',
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const MetricsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/configure',
              name: 'configure',
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ConfigureScreen()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/workout/summary/:id',
        name: 'workout.summary',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = int.parse(state.pathParameters['id']!);
          return NoTransitionPage(key: state.pageKey, child: WorkoutSummaryScreen(workoutId: id));
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const OnboardingScreen());
        },
      ),
      GoRoute(
        path: '/settings/edit',
        name: 'settings.edit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const EditSettingsScreen());
        },
      ),
      GoRoute(
        path: '/food/log',
        name: 'food.log',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final ds = state.uri.queryParameters['date'];
          DateTime? date;
          if (ds != null && ds.isNotEmpty) {
            try {
              final parts = ds.split('-');
              if (parts.length == 3) {
                date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              }
            } catch (_) {}
          }
          return NoTransitionPage(key: state.pageKey, child: FoodLogScreen(date: date));
        },
      ),
      GoRoute(
        path: '/meals/today',
        name: 'meals.today',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const MealsTodayScreen());
        },
      ),
      GoRoute(
        path: '/meals/by-date',
        name: 'meals.byDate',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final ds = state.uri.queryParameters['date']; // yyyy-MM-dd
          DateTime date = DateTime.now();
          if (ds != null && ds.isNotEmpty) {
            try {
              final parts = ds.split('-');
              if (parts.length == 3) {
                date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              }
            } catch (_) {}
          }
          return NoTransitionPage(key: state.pageKey, child: MealsAtDateScreen(date: date));
        },
      ),
      GoRoute(
        path: '/food/scan',
        name: 'food.scan',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final meal = state.uri.queryParameters['meal'];
          final ds = state.uri.queryParameters['date'];
          DateTime? date;
          if (ds != null && ds.isNotEmpty) {
            try {
              final p = ds.split('-');
              if (p.length == 3) date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
            } catch (_) {}
          }
          return NoTransitionPage(key: state.pageKey, child: ScanFoodScreen(initialMealType: meal, initialDate: date));
        },
      ),
      GoRoute(
        path: '/food/search',
        name: 'food.search',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final meal = state.uri.queryParameters['meal'];
          final ds = state.uri.queryParameters['date'];
          DateTime? date;
          if (ds != null && ds.isNotEmpty) {
            try {
              final p = ds.split('-');
              if (p.length == 3) date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
            } catch (_) {}
          }
          return NoTransitionPage(key: state.pageKey, child: FoodSearchScreen(initialMealType: meal, initialDate: date));
        },
      ),
      GoRoute(
        path: '/workout/detail/:id',
        name: 'workout.detail',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = int.parse(state.pathParameters['id']!);
          return NoTransitionPage(key: state.pageKey, child: WorkoutDetailScreen(workoutId: id));
        },
      ),
      GoRoute(
        path: '/workout/templates',
        name: 'workout.templates',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          int? initialId;
          if (extra is Map) {
            final v = extra['initialTemplateId'];
            if (v is int) initialId = v; 
          } else if (extra is int) {
            initialId = extra;
          }
          return NoTransitionPage(key: state.pageKey, child: TemplatesScreen(initialTemplateId: initialId));
        },
      ),
      GoRoute(
        path: '/workout/schedule',
        name: 'workout.schedule',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const ScheduleScreen());
        },
      ),
      GoRoute(
        path: '/task/add',
        name: 'task.add',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(key: state.pageKey, child: const _StubScreen('Add Task (stub)'));
        },
      ),
    ],
    debugLogDiagnostics: true,
  );
});
