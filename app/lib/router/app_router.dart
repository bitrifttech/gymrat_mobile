import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:app/features/home/ui/home_screen.dart';
import 'package:app/features/onboarding/ui/launch_screen.dart';
import 'package:app/features/onboarding/ui/onboarding_screen.dart';
import 'package:app/features/settings/ui/edit_settings_screen.dart';

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
          return const NoTransitionPage(child: _StubScreen('Food Logging (stub)'));
        },
      ),
      GoRoute(
        path: '/workout/start',
        name: 'workout.start',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const NoTransitionPage(child: _StubScreen('Start Workout (stub)'));
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
