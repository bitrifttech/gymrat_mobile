import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/router/app_router.dart';
import 'package:app/core/db_provider.dart';
import 'package:app/core/demo_seed.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    // Fire-and-forget demo seed
    ref.read(appDatabaseProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(appDatabaseProvider);
      await seedDemoData(db);
    });
    return MaterialApp.router(
      title: 'GymRat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}
