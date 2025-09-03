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
          return const NoTransitionPage(child: LaunchScreen());
        },
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
      GoRoute(
        path: '/metrics',
        name: 'metrics',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: MetricsScreen());
        },
      ),
      GoRoute(
        path: '/workout/summary/:id',
        name: 'workout.summary',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = int.parse(state.pathParameters['id']!);
          return NoTransitionPage(child: WorkoutSummaryScreen(workoutId: id));
        },
      ),
      GoRoute(
        path: '/meals/history',
        name: 'meals.history',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: MealHistoryScreen());
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: OnboardingScreen());
        },
      ),
      GoRoute(
        path: '/settings/edit',
        name: 'settings.edit',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: EditSettingsScreen());
        },
      ),
      GoRoute(
        path: '/food/log',
        name: 'food.log',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: FoodLogScreen());
        },
      ),
      GoRoute(
        path: '/meals/today',
        name: 'meals.today',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: MealsTodayScreen());
        },
      ),
      GoRoute(
        path: '/food/scan',
        name: 'food.scan',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: ScanFoodScreen());
        },
      ),
      GoRoute(
        path: '/food/search',
        name: 'food.search',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: FoodSearchScreen());
        },
      ),
      GoRoute(
        path: '/workout/history',
        name: 'workout.history',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: WorkoutHistoryScreen());
        },
      ),
      GoRoute(
        path: '/workout/detail/:id',
        name: 'workout.detail',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final id = int.parse(state.pathParameters['id']!);
          return NoTransitionPage(child: WorkoutDetailScreen(workoutId: id));
        },
      ),
      GoRoute(
        path: '/workout/templates',
        name: 'workout.templates',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: TemplatesScreen());
        },
      ),
      GoRoute(
        path: '/workout/schedule',
        name: 'workout.schedule',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: ScheduleScreen());
        },
      ),
      GoRoute(
        path: '/task/add',
        name: 'task.add',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: _StubScreen('Add Task (stub)'));
        },
      ),
    ],
    debugLogDiagnostics: true,
  );
});
