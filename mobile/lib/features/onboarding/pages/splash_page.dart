import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Timer _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        context.go(RouteNames.onboarding);
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
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
