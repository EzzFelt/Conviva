import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _openInitialDestination();
  }

  Future<void> _openInitialDestination() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final session = await ref.read(currentUserProvider.future);
      if (!mounted) return;

      if (session == null) {
        context.go(RouteNames.onboarding);
      } else {
        await AuthenticatedUserNavigator.open(context, session);
      }
    } catch (_) {
      if (!mounted) return;

      try {
        await ref.read(currentUserProvider.notifier).signOut();
      } catch (_) {
        // Mesmo sem conseguir limpar a sessão, o onboarding deve abrir.
      }

      if (!mounted) return;
      context.go(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Semantics(
          image: true,
          label: 'Conviva',
          child: Image.asset(
            AssetPaths.logo,
            width: sizes.xxl * 3.75,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
