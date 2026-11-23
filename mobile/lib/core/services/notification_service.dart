import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/routine/models/routine_task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'conviva_notifications';
  static const _channelName = 'Notificações do Conviva';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void>? _initialization;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _familyLinksSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _chatMessageSubscriptions = {};
  final Map<String, Map<String, dynamic>> _chatDocuments = {};
  List<RoutineTask> _routineTasks = const [];
  Set<String> _familyNotificationElderIds = const {};
  String? _userId;
  String? _institutionId;
  String? _token;
  bool _isFamilyAccount = false;
  bool _localPermissionGranted = false;
  bool _messageNotificationsEnabled = true;
  bool _reminderNotificationsEnabled = true;
  Future<void> _taskScheduleQueue = Future<void>.value();
  Timer? _dueTasksTimer;
  final Set<String> _recordedTaskKeys = {};
  bool _exactAlarmsAllowed = false;
  DateTime? _catchUpSince;
  void Function(String path)? _onNotificationTap;
  String? _pendingPayload;
  // Notificações cujo toque já abriu a tela: não voltam como "novas" no sino.
  final Set<String> _openedNotificationIds = {};

  Future<void> initialize({
    required void Function(String path) onNotificationTap,
  }) {
    _onNotificationTap = onNotificationTap;
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!_isAndroid) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        unawaited(_openPayload(response.payload));
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Mensagens e lembretes de tarefas',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro ao receber notificação em primeiro plano: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openRemoteMessage,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro ao abrir notificação: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (token) {
        _token = token;
        unawaited(_saveToken(token));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro ao atualizar o token de notificações: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingPayload = jsonEncode(initialMessage.data);
    }
  }

  Future<void> bindUser(
    String? userId, {
    String? institutionId,
    bool isFamilyAccount = false,
  }) async {
    await initialize(onNotificationTap: _onNotificationTap ?? (_) {});
    if (_userId == userId &&
        _institutionId == institutionId &&
        _isFamilyAccount == isFamilyAccount) {
      if (userId == null) await _cancelTaskRemindersExcept(null);
      return;
    }

    _dueTasksTimer?.cancel();
    _dueTasksTimer = null;
    _recordedTaskKeys.clear();
    _openedNotificationIds.clear();

    await _cancelTaskRemindersExcept(userId);
    await _removeToken();
    await _stopWatchingChats();
    await _familyLinksSubscription?.cancel();
    _familyLinksSubscription = null;
    _userId = userId;
    _institutionId = institutionId;
    _isFamilyAccount = isFamilyAccount;
    _familyNotificationElderIds = const {};
    _token = null;
    // As tarefas NÃO são apagadas aqui: elas chegam do Firestore em paralelo
    // ao bindUser e eram descartadas por essa limpeza. Quem limpa ao trocar
    // de conta é o app.dart, via updateRoutineTasks(const []).
    if (userId == null || !_isAndroid) return;

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    _localPermissionGranted =
        await androidNotifications?.requestNotificationsPermission() ?? false;
    await _requestExactAlarmsOnce(androidNotifications);

    // Marca de quando o app foi usado pela última vez: mensagens mais novas
    // que isso chegaram com o app fechado e entram no sino ao abrir.
    _catchUpSince = await _readLastCheck(userId);
    unawaited(_touchLastCheck());
    _watchChats(userId, institutionId);
    if (isFamilyAccount) _watchFamilyLinks(userId, institutionId);

    final pendingPayload = _pendingPayload;
    _pendingPayload = null;
    if (pendingPayload != null) {
      unawaited(_openPayload(pendingPayload));
    }

    try {
      final permission = await _messaging.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.denied) {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _token = token;
          await _saveToken(token);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Não foi possível registrar notificações: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    await _syncRoutineTaskReminders();

    // Enquanto o app estiver aberto, registra no sino as tarefas que
    // chegaram na hora (sem precisar de servidor).
    _dueTasksTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_recordDueTaskNotifications());
      unawaited(_touchLastCheck());
    });
  }

  String _lastCheckKey(String userId) =>
      'conviva_notifications_checked_$userId';

  Future<DateTime?> _readLastCheck(String userId) async {
    try {
      final millis = await SharedPreferencesAsync().getInt(
        _lastCheckKey(userId),
      );
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  Future<void> _touchLastCheck() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await SharedPreferencesAsync().setInt(
        _lastCheckKey(userId),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // A marca é só um reforço; falhar aqui não atrapalha o app.
    }
  }

  /// Registra no sino as mensagens que chegaram enquanto o app estava fechado.
  Future<void> _catchUpMessages(
    String chatId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) async {
    final since = _catchUpSince;
    if (since == null) return;

    for (final message in messages.reversed) {
      final createdAt = message.data()['createdAt'];
      if (createdAt is! Timestamp || !createdAt.toDate().isAfter(since)) {
        continue;
      }

      await _handleNewMessage(chatId, message, showLocal: false);
    }
  }

  /// Em Android 12+ o alarme exato precisa de autorização do usuário.
  /// Pedimos uma única vez, para não ficar abrindo a tela de ajustes.
  Future<void> _requestExactAlarmsOnce(
    AndroidFlutterLocalNotificationsPlugin? android,
  ) async {
    if (android == null) return;

    try {
      if (await android.canScheduleExactNotifications() ?? false) return;

      const key = 'conviva_exact_alarm_prompted';
      final store = SharedPreferencesAsync();
      if (await store.getBool(key) ?? false) return;

      await store.setBool(key, true);
      await android.requestExactAlarmsPermission();
    } catch (error, stackTrace) {
      debugPrint('Não foi possível pedir permissão de alarme exato: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updatePreferences({
    required bool messageNotificationsEnabled,
    required bool reminderNotificationsEnabled,
  }) {
    _messageNotificationsEnabled = messageNotificationsEnabled;
    _reminderNotificationsEnabled = reminderNotificationsEnabled;
    unawaited(_syncRoutineTaskReminders());
  }

  Future<void> updateRoutineTasks(List<RoutineTask> tasks) async {
    _routineTasks = List<RoutineTask>.unmodifiable(tasks);
    await _syncRoutineTaskReminders();
  }

  void _watchChats(String userId, String? institutionId) {
    if (institutionId == null || institutionId.isEmpty) return;

    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('institutionId', isEqualTo: institutionId)
        .snapshots()
        .listen(
          (snapshot) {
            final currentChatIds = snapshot.docs.map((chat) => chat.id).toSet();
            for (final chat in snapshot.docs) {
              _chatDocuments[chat.id] = chat.data();
              _chatMessageSubscriptions.putIfAbsent(
                chat.id,
                () => _watchChatMessages(chat.id),
              );
            }

            final removedChatIds = _chatMessageSubscriptions.keys
                .where((chatId) => !currentChatIds.contains(chatId))
                .toList();
            for (final chatId in removedChatIds) {
              unawaited(_chatMessageSubscriptions.remove(chatId)?.cancel());
              _chatDocuments.remove(chatId);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao acompanhar conversas para notificações: $error',
            );
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  void _watchFamilyLinks(String userId, String? institutionId) {
    if (institutionId == null || institutionId.isEmpty) return;

    _familyLinksSubscription = FirebaseFirestore.instance
        .collection('familyLinks')
        .where('familiarId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(
          (snapshot) {
            _familyNotificationElderIds = {
              for (final link in snapshot.docs)
                if (link.data()['institutionId']?.toString() == institutionId &&
                    link.data()['receiveNotifications'] != false)
                  link.data()['elderId']?.toString() ?? '',
            }..remove('');
            unawaited(_syncRoutineTaskReminders());
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Erro ao acompanhar preferências de vínculo: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _watchChatMessages(
    String chatId,
  ) {
    var isInitialSnapshot = true;
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen(
          (snapshot) {
            if (isInitialSnapshot) {
              isInitialSnapshot = false;
              unawaited(_catchUpMessages(chatId, snapshot.docs));
              return;
            }

            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                unawaited(_handleNewMessage(chatId, change.doc));
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Erro ao acompanhar mensagens para notificações: $error',
            );
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  Future<void> _handleNewMessage(
    String chatId,
    DocumentSnapshot<Map<String, dynamic>> message, {
    bool showLocal = true,
  }) async {
    final userId = _userId;
    final messageData = message.data();
    if (messageData == null) return;
    final senderId = messageData['senderId']?.toString();
    if (userId == null || senderId == null || senderId == userId) return;

    final chat = _chatDocuments[chatId] ?? const <String, dynamic>{};
    final participantsData = Map<String, dynamic>.from(
      chat['participantsData'] as Map? ?? const {},
    );
    final senderData = Map<String, dynamic>.from(
      participantsData[senderId] as Map? ?? const {},
    );
    final title = senderData['name']?.toString().trim();
    final body = switch (messageData['type']?.toString()) {
      'image' => 'Você recebeu uma imagem.',
      'audio' => 'Você recebeu uma mensagem de voz.',
      _ => _messagePreview(messageData['text']?.toString() ?? ''),
    };
    if (!_messageNotificationsEnabled) return;

    final notificationId = 'message_${chatId}_${message.id}';
    // O usuário já abriu esta conversa tocando no push: não recria no sino.
    if (_openedNotificationIds.contains(notificationId)) return;
    final notificationTitle = title == null || title.isEmpty
        ? 'Nova mensagem'
        : title;
    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    var shouldShow = true;
    try {
      shouldShow = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final existing = await transaction.get(reference);
        if (existing.exists) return false;

        transaction.set(reference, {
          'type': 'message',
          'title': notificationTitle.length > 120
              ? notificationTitle.substring(0, 120)
              : notificationTitle,
          'body': body,
          'chatId': chatId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (error, stackTrace) {
      debugPrint('Não foi possível salvar o histórico da mensagem: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!shouldShow || !showLocal || !_localPermissionGranted) return;
    try {
      await _localNotifications.show(
        _notificationId(notificationId),
        notificationTitle,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Mensagens e lembretes de tarefas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: jsonEncode({
          'notificationId': notificationId,
          'type': 'message',
          'chatId': chatId,
        }),
      );
    } catch (error, stackTrace) {
      debugPrint('Não foi possível exibir a notificação da mensagem: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _messagePreview(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return 'Nova mensagem.';
    return normalized.length > 120
        ? '${normalized.substring(0, 117)}...'
        : normalized;
  }

  Future<void> _syncRoutineTaskReminders() {
    final operation = _taskScheduleQueue.then(
      (_) => _replaceRoutineTaskReminders(),
    );
    _taskScheduleQueue = operation;
    return operation;
  }

  Future<void> _replaceRoutineTaskReminders() async {
    if (!_isAndroid || _initialization == null) return;

    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      for (final notification in pending) {
        if (_isReminderForCurrentUser(notification.payload)) {
          await _localNotifications.cancel(notification.id);
        }
      }

      // O registro no sino não depende da permissão de notificação.
      unawaited(_recordDueTaskNotifications());

      if (_userId == null ||
          !_reminderNotificationsEnabled ||
          !_localPermissionGranted) {
        return;
      }

      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        _exactAlarmsAllowed =
            await android?.canScheduleExactNotifications() ?? false;
      } catch (_) {
        _exactAlarmsAllowed = false;
      }

      final now = tz.TZDateTime.now(tz.local);
      final tasks = _tasksForReminders();
      for (final task in tasks) {
        if (!task.repeatWeekly) {
          final scheduledDate = tz.TZDateTime.from(task.startAt, tz.local);
          if (scheduledDate.isAfter(now)) {
            await _scheduleTask(task, scheduledDate);
          }
          continue;
        }

        for (final weekday in task.repeatWeekdays) {
          final scheduledDate = _nextTaskOccurrence(task, weekday, now);
          if (scheduledDate == null) continue;
          await _scheduleTask(task, scheduledDate, weekday: weekday);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Não foi possível agendar os lembretes locais: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<RoutineTask> _tasksForReminders() {
    return _isFamilyAccount
        ? _routineTasks
              .where(
                (task) => _familyNotificationElderIds.contains(task.elderId),
              )
              .toList()
        : _routineTasks;
  }

  String _scheduleKey(RoutineTask task, {int? weekday}) {
    return '${task.elderId}_${task.id}_${weekday ?? 'once'}';
  }

  /// Registra no sino (users/{uid}/notifications) as tarefas cujo horário
  /// já chegou. O id do documento é fixo por tarefa e por dia, então
  /// registrar de novo não duplica.
  ///
  /// Funciona com o app aberto (a cada 30 s) e, ao abrir o app, recupera o
  /// que chegou nas últimas 12 horas.
  Future<void> _recordDueTaskNotifications() async {
    final userId = _userId;
    if (userId == null || !_isAndroid || !_reminderNotificationsEnabled) {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [today.subtract(const Duration(days: 1)), today];

    for (final task in _tasksForReminders()) {
      for (final day in days) {
        if (!task.occursOn(day)) continue;

        final occurrence = task.startOn(day);
        final elapsed = now.difference(occurrence);
        if (elapsed.isNegative || elapsed > const Duration(hours: 12)) {
          continue;
        }

        final dateKey =
            '${day.year}${day.month.toString().padLeft(2, '0')}'
            '${day.day.toString().padLeft(2, '0')}';
        final notificationId = 'task_${task.elderId}_${task.id}_$dateKey';
        if (!_recordedTaskKeys.add(notificationId)) continue;

        try {
          await _recordTaskNotification(
            userId: userId,
            task: task,
            occurrence: occurrence,
            notificationId: notificationId,
            isLive: elapsed <= const Duration(minutes: 2),
          );
        } catch (error, stackTrace) {
          // Tenta de novo no próximo ciclo (ex.: sem internet).
          _recordedTaskKeys.remove(notificationId);
          debugPrint('Não foi possível registrar o lembrete no sino: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
  }

  Future<void> _recordTaskNotification({
    required String userId,
    required RoutineTask task,
    required DateTime occurrence,
    required String notificationId,
    required bool isLive,
  }) async {
    const title = 'Hora da tarefa';
    var body = 'Está na hora de ${task.title.trim()}.';
    if (body.length > 120) body = '${body.substring(0, 117)}...';

    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId);

    final created = await FirebaseFirestore.instance.runTransaction((
      transaction,
    ) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return false;

      transaction.set(reference, {
        'type': 'task',
        'title': title,
        'body': body,
        'elderId': task.elderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });

    // Reforço: se o app está aberto na hora, garante o aviso mesmo que o
    // alarme do sistema atrase. Usa o mesmo id do alarme agendado, então o
    // Android substitui em vez de duplicar.
    if (!created || !isLive || !_localPermissionGranted) return;

    await _localNotifications.show(
      _notificationId(
        _scheduleKey(
          task,
          weekday: task.repeatWeekly ? occurrence.weekday : null,
        ),
      ),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Mensagens e lembretes de tarefas',
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode({
        'notificationId': notificationId,
        'type': 'task',
        'elderId': task.elderId,
      }),
    );
  }

  tz.TZDateTime? _nextTaskOccurrence(
    RoutineTask task,
    int weekday,
    tz.TZDateTime now,
  ) {
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    final firstScheduledDate = RoutineTask.dateOnly(task.startAt);
    for (var daysAhead = 0; daysAhead < 14; daysAhead++) {
      if (date.weekday == weekday &&
          !DateTime(
            date.year,
            date.month,
            date.day,
          ).isBefore(firstScheduledDate)) {
        final occurrence = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          task.startAt.hour,
          task.startAt.minute,
        );
        if (occurrence.isAfter(now)) return occurrence;
      }
      date = date.add(const Duration(days: 1));
    }
    return null;
  }

  Future<void> _scheduleTask(
    RoutineTask task,
    tz.TZDateTime scheduledDate, {
    int? weekday,
  }) {
    final userId = _userId;
    if (userId == null) return Future<void>.value();

    final scheduleKey = _scheduleKey(task, weekday: weekday);
    final payload = jsonEncode({
      'source': 'routine_task',
      'ownerId': userId,
      'type': 'task',
      'elderId': task.elderId,
      'taskId': task.id,
    });

    return _localNotifications.zonedSchedule(
      _notificationId(scheduleKey),
      'Hora da tarefa',
      'Está na hora de ${task.title}.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Mensagens e lembretes de tarefas',
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      // Exato quando o usuário autorizou; senão o Android pode atrasar
      // o lembrete em vários minutos (modo economia/Doze).
      androidScheduleMode: _exactAlarmsAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: weekday == null
          ? null
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  bool _isReminderForCurrentUser(String? payload) {
    if (payload == null) return false;
    try {
      final data = jsonDecode(payload);
      return data is Map &&
          data['source'] == 'routine_task' &&
          data['ownerId'] == _userId;
    } on FormatException {
      return false;
    }
  }

  Future<void> _cancelTaskRemindersExcept(String? userId) async {
    if (!_isAndroid || _initialization == null) return;
    final pending = await _localNotifications.pendingNotificationRequests();
    for (final notification in pending) {
      final payload = notification.payload;
      if (payload == null) continue;
      try {
        final data = jsonDecode(payload);
        if (data is Map &&
            data['source'] == 'routine_task' &&
            data['ownerId'] != userId) {
          await _localNotifications.cancel(notification.id);
        }
      } on FormatException {
        continue;
      }
    }
  }

  Future<void> dismissNotifications(Iterable<String> notificationIds) async {
    if (!_isAndroid) return;

    for (final notificationId in notificationIds) {
      await _localNotifications.cancel(_notificationId(notificationId));
    }
  }

  /// Remove da bandeja tudo o que o app já mostrou, inclusive os pushes
  /// desenhados pelo próprio sistema (FCM), que não têm o id local.
  /// Lembretes agendados (ainda não disparados) NÃO são afetados.
  Future<void> clearDeliveredNotifications() async {
    if (!_isAndroid) return;

    try {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final active = await android?.getActiveNotifications() ?? const [];
      for (final notification in active) {
        final id = notification.id;
        if (id == null) continue;
        await _localNotifications.cancel(id, tag: notification.tag);
      }
    } catch (error, stackTrace) {
      debugPrint('Não foi possível limpar a bandeja: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> _stopWatchingChats() async {
    await _chatsSubscription?.cancel();
    _chatsSubscription = null;
    await Future.wait(
      _chatMessageSubscriptions.values.map(
        (subscription) => subscription.cancel(),
      ),
    );
    _chatMessageSubscriptions.clear();
    _chatDocuments.clear();
  }

  Future<void> _saveToken(String token) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .set({
            'token': token,
            'platform': 'android',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (error, stackTrace) {
      debugPrint('Não foi possível salvar o token de notificações: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _removeToken() async {
    final userId = _userId;
    final token = _token;
    if (userId == null || token == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .delete();
    } catch (error, stackTrace) {
      debugPrint('Não foi possível remover o token anterior: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final type = message.data['type']?.toString();
    if ((type == 'message' && !_messageNotificationsEnabled) ||
        (type == 'task' && !_reminderNotificationsEnabled)) {
      return;
    }

    final notification = message.notification;
    if (notification == null || !_localPermissionGranted) return;

    try {
      final remoteNotificationId =
          message.data['notificationId']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString();
      await _localNotifications.show(
        _notificationId(remoteNotificationId),
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Mensagens e lembretes de tarefas',
            importance: Importance.max,
            priority: Priority.high,
            onlyAlertOnce: true,
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error, stackTrace) {
      debugPrint('Não foi possível exibir a notificação: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openRemoteMessage(RemoteMessage message) {
    return _openPayload(jsonEncode(message.data));
  }

  Future<void> _openPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    if (_userId == null) {
      _pendingPayload = payload;
      return;
    }

    try {
      final data = jsonDecode(payload);
      if (data is! Map) return;

      final notificationId = data['notificationId']?.toString();
      final userId = _userId;
      if (notificationId != null &&
          notificationId.isNotEmpty &&
          userId != null) {
        _openedNotificationIds.add(notificationId);
        await dismissNotifications([notificationId]);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'read': true});
      }

      final type = data['type']?.toString();
      final path = switch (type) {
        'message' => _chatPath(data['chatId']?.toString()),
        'task' => _routinePath(data['elderId']?.toString()),
        'password_reset' => _passwordResetPath(
          data['requestId']?.toString(),
          data['elderName']?.toString(),
        ),
        _ => null,
      };

      if (path != null) {
        _onNotificationTap?.call(path);
      }
    } on FormatException catch (error, stackTrace) {
      debugPrint('Dados inválidos ao abrir uma notificação: $error');
      debugPrintStack(stackTrace: stackTrace);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Não foi possível marcar a notificação como lida: $error');
      debugPrintStack(stackTrace: stackTrace);
      _openPayloadWithoutMarkingRead(payload);
    }
  }

  void _openPayloadWithoutMarkingRead(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is! Map) return;
      final path = switch (data['type']?.toString()) {
        'message' => _chatPath(data['chatId']?.toString()),
        'task' => _routinePath(data['elderId']?.toString()),
        'password_reset' => _passwordResetPath(
          data['requestId']?.toString(),
          data['elderName']?.toString(),
        ),
        _ => null,
      };
      if (path != null) _onNotificationTap?.call(path);
    } on FormatException catch (error, stackTrace) {
      debugPrint('Dados inválidos ao abrir uma notificação: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String? _chatPath(String? chatId) {
    final normalizedId = chatId?.trim();
    return normalizedId == null || normalizedId.isEmpty
        ? null
        : '/chat/${Uri.encodeComponent(normalizedId)}';
  }

  String? _routinePath(String? elderId) {
    final normalizedId = elderId?.trim();
    return normalizedId == null || normalizedId.isEmpty
        ? null
        : '/routine/${Uri.encodeComponent(normalizedId)}';
  }

  String? _passwordResetPath(String? requestId, String? elderName) {
    final normalizedId = requestId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) return null;

    final name = elderName?.trim();
    final query = name == null || name.isEmpty
        ? ''
        : '?elderName=${Uri.encodeQueryComponent(name)}';
    return '/password-reset/approval/'
        '${Uri.encodeComponent(normalizedId)}$query';
  }

  Future<void> dispose() async {
    _dueTasksTimer?.cancel();
    _dueTasksTimer = null;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _stopWatchingChats();
    await _familyLinksSubscription?.cancel();
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
