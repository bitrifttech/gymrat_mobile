import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/onboarding/data/onboarding_repository.dart';

class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(_onboardingCheckProvider, (prev, next) {
      next.whenData((isComplete) {
        if (isComplete) {
          context.goNamed('home');
        } else {
          context.goNamed('onboarding');
        }
      });
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

final _onboardingCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(onboardingRepositoryProvider);
  return repo.isOnboardingComplete();
});
