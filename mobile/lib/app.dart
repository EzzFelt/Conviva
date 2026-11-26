import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';
import 'core/routes/app_router.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/models/account_type.dart';
import 'features/auth/providers/current_user_provider.dart';
import 'features/routine/models/routine_elder_summary.dart';
import 'features/routine/models/routine_task.dart';
import 'features/routine/providers/routine_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final Map<String, ProviderSubscription<AsyncValue<List<RoutineTask>>>>
  _routineTaskSubscriptions = {};
  final Map<String, List<RoutineTask>> _routineTasksByElder = {};
  String? _notificationUserId;
  String? _notificationInstitutionId;
  bool _notificationIsFamilyAccount = false;
  bool _hasBoundNotificationUser = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentUserProvider, (previous, next) {
      if (next.isLoading && next.asData == null) return;
      final session = next.asData?.value;
      final userId = session?.uid;
      final institutionId = session?.institutionId;
      final isFamilyAccount = session?.accountType == AccountType.family;
      if (_hasBoundNotificationUser &&
          _notificationUserId == userId &&
          _notificationInstitutionId == institutionId &&
          _notificationIsFamilyAccount == isFamilyAccount) {
        return;
      }

      _hasBoundNotificationUser = true;
      _notificationUserId = userId;
      _notificationInstitutionId = institutionId;
      _notificationIsFamilyAccount = isFamilyAccount;
      _clearRoutineTaskSubscriptions();
      unawaited(NotificationService.instance.updateRoutineTasks(const []));
      unawaited(
        _bindNotificationUser(
          userId,
          institutionId: institutionId,
          isFamilyAccount: isFamilyAccount,
        ),
      );
    }, fireImmediately: true);
    ref.listenManual(accessibleRoutineEldersProvider, (previous, next) {
      final elders = next.asData?.value;
      if (elders != null) _watchRoutineTasks(elders);
    }, fireImmediately: true);
    ref.listenManual(appSettingsProvider, (previous, next) {
      NotificationService.instance.updatePreferences(
        messageNotificationsEnabled: next.messageNotifications,
        reminderNotificationsEnabled: next.reminderNotifications,
      );
    }, fireImmediately: true);
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.instance.initialize(
        onNotificationTap: AppRouter.router.go,
      );
    } catch (error, stackTrace) {
      debugPrint('Não foi possível inicializar as notificações: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              (systemFontScale * settings.fontScale).clamp(0.8, 2.0),
            ),
          ),
          child: child,
        );
      },
    );
  }

  void _watchRoutineTasks(List<RoutineElderSummary> elders) {
    final elderIds = elders.map((elder) => elder.id).toSet();
    for (final elderId
        in _routineTaskSubscriptions.keys
            .where((id) => !elderIds.contains(id))
            .toList()) {
      _routineTaskSubscriptions.remove(elderId)?.close();
      _routineTasksByElder.remove(elderId);
    }

    for (final elder in elders) {
      _routineTaskSubscriptions.putIfAbsent(
        elder.id,
        () =>
            ref.listenManual(routineTasksProvider(elder.id), (previous, next) {
              final tasks = next.asData?.value;
              if (tasks != null) {
                _routineTasksByElder[elder.id] = tasks;
                _scheduleAccessibleTasks();
              } else if (next.hasError) {
                debugPrint(
                  'Não foi possível carregar tarefas para notificações: '
                  '${next.error}',
                );
              }
            }, fireImmediately: true),
      );
    }

    _scheduleAccessibleTasks();
  }

  void _scheduleAccessibleTasks() {
    unawaited(
      NotificationService.instance.updateRoutineTasks(
        _routineTasksByElder.values.expand((tasks) => tasks).toList(),
      ),
    );
  }

  void _clearRoutineTaskSubscriptions() {
    for (final subscription in _routineTaskSubscriptions.values) {
      subscription.close();
    }
    _routineTaskSubscriptions.clear();
    _routineTasksByElder.clear();
  }

  Future<void> _bindNotificationUser(
    String? userId, {
    String? institutionId,
    bool isFamilyAccount = false,
  }) async {
    try {
      await NotificationService.instance.bindUser(
        userId,
        institutionId: institutionId,
        isFamilyAccount: isFamilyAccount,
      );
    } catch (error, stackTrace) {
      debugPrint('Não foi possível iniciar as notificações: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _clearRoutineTaskSubscriptions();
    super.dispose();
  }
}
