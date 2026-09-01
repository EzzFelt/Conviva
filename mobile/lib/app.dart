import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/themes/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Conviva',
      theme: AppTheme.light(settings),
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context);
        final systemFontScale = mediaQuery.textScaler.scale(1);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              systemFontScale * settings.fontScale,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
