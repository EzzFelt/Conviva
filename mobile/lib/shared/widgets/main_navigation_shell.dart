import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../features/auth/providers/authenticated_user_navigator.dart';
import '../../features/auth/providers/current_user_provider.dart';
import 'main_navigation_bar.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  int get _currentIndex {
    if (location.startsWith(RouteNames.menu) ||
        location.startsWith(RouteNames.chat) ||
        location.startsWith(RouteNames.routine) ||
        location.startsWith(RouteNames.reportStart)) {
      return 1;
    }

    if (location.startsWith(RouteNames.profile)) {
      return 2;
    }

    if (location.startsWith(RouteNames.settings)) {
      return 3;
    }

    return 0;
  }

  Future<void> _goToHome(BuildContext context, WidgetRef ref) async {
    try {
      final session = await ref.read(currentUserProvider.future);
      if (!context.mounted) return;

      if (session == null) {
        context.go(RouteNames.onboarding);
        return;
      }

      await AuthenticatedUserNavigator.open(context, session);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  void _selectDestination(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        _goToHome(context, ref);
        return;
      case 1:
        context.go(RouteNames.menu);
        return;
      case 2:
        context.go(RouteNames.profile);
        return;
      case 3:
        context.go(RouteNames.settings);
        return;
    }
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentUserProvider);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: location.startsWith('${RouteNames.chat}/')
          ? null
          : MainNavigationBar(
              currentIndex: _currentIndex,
              onDestinationSelected: (index) {
                _selectDestination(context, ref, index);
              },
            ),
    );
  }
}
