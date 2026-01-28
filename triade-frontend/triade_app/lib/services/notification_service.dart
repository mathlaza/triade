import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/material.dart';

/// Serviço singleton para gerenciar notificações de tarefas agendadas
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Configurações
  static const String _enabledKey = 'notifications_enabled';

  // Plugin de notificações do sistema
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Estado
  bool _isEnabled = true;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _timezoneInitialized = false;

  // Getter para saber se está habilitado
  bool get isEnabled => _isEnabled;
  bool get hasPermission => _hasPermission;
  bool get isInitialized => _isInitialized;

  /// Inicializa o timezone de forma robusta
  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;

    try {
      // Inicializa todos os dados de timezone
      tz_data.initializeTimeZones();

      // Obtém o offset atual do dispositivo
      final now = DateTime.now();
      final offsetInHours = now.timeZoneOffset.inHours;
      final offsetMinutes = now.timeZoneOffset.inMinutes % 60;

      // Tenta encontrar o timezone baseado no offset
      // Para Brasil (GMT-3), usamos America/Sao_Paulo
      String locationName;

      // Mapeamento de offsets comuns para timezones
      if (offsetInHours == -3 && offsetMinutes == 0) {
        locationName = 'America/Sao_Paulo';
      } else if (offsetInHours == -2 && offsetMinutes == 0) {
        locationName = 'America/Sao_Paulo'; // Horário de verão
      } else if (offsetInHours == 0 && offsetMinutes == 0) {
        locationName = 'UTC';
      } else {
        // Fallback: tenta usar o nome do timezone do sistema
        // ou calcula baseado no offset
        try {
          // Tenta usar o timezone name do sistema
          final systemTzName = now.timeZoneName;
          if (tz.timeZoneDatabase.locations.containsKey(systemTzName)) {
            locationName = systemTzName;
          } else {
            // Usa UTC como fallback seguro
            locationName = 'UTC';
          }
        } catch (e) {
          locationName = 'UTC';
        }
      }

      // Define o timezone local
      final location = tz.getLocation(locationName);
      tz.setLocalLocation(location);

      _timezoneInitialized = true;
    } catch (e, stackTrace) {
      // Reporta erro ao Sentry
      Sentry.captureException(e, stackTrace: stackTrace);

      // Fallback para UTC se tudo falhar
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _timezoneInitialized = true;
      } catch (e2, stackTrace2) {
        Sentry.captureException(e2, stackTrace: stackTrace2);
      }
    }
  }

  /// Inicializa o serviço de notificações
  Future<void> init() async {
    if (_isInitialized) return;

    try {

      // 1. Inicializa timezone PRIMEIRO
      await _initializeTimezone();

      // 2. Carrega preferência de notificações
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_enabledKey) ?? true;

      // 3. Configurações para Android - usa ícone específico para notificações
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      // 4. Configurações para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 5. Inicializa o plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 6. Solicita permissão no Android 13+
      if (Platform.isAndroid) {
        _hasPermission = await _requestAndroidPermission();
      } else {
        _hasPermission = true;
      }

      // 7. Cria o canal de notificação explicitamente (importante para release!)
      await _createNotificationChannel();

      _isInitialized = true;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Cria o canal de notificação explicitamente
  Future<void> _createNotificationChannel() async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return;

      // Cria o canal com todas as configurações incluindo som customizado
      const channel = AndroidNotificationChannel(
        'task_notifications_v3',
        'Notificações de Tarefas',
        description: 'Notificações quando o horário de uma tarefa chega',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(channel);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Solicita permissão de notificação no Android 13+
  Future<bool> _requestAndroidPermission() async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return false;

      // Solicita permissão de notificação (Android 13+)
      final notificationGranted =
          await androidPlugin.requestNotificationsPermission();

      // Solicita permissão de alarme exato (Android 12+)
      await androidPlugin.requestExactAlarmsPermission();

      return notificationGranted == true;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Força nova solicitação de permissão (útil para re-pedir após negação)
  Future<bool> requestPermissionAgain() async {
    if (Platform.isAndroid) {
      _hasPermission = await _requestAndroidPermission();
      return _hasPermission;
    }
    return true;
  }

  /// Callback quando usuário toca na notificação
  void _onNotificationTapped(NotificationResponse response) {
    // Ação futura: navegar para a tarefa específica
  }

  /// Habilita ou desabilita notificações
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);

      if (!enabled) {
        await _notifications.cancelAll();
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Agenda notificações para todas as tarefas do dia com horário
Future<void> scheduleTaskNotifications(List<Task> tasks) async {
  if (!_isEnabled) return;

  if (!_isInitialized) {
    await init();
  }

  // Cancela notificações anteriores para evitar duplicatas
  await _notifications.cancelAll();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final task in tasks) {
    // Só agenda tarefas de hoje, com horário, ativas (não concluídas)
    if (task.scheduledTime == null) continue;
    if (task.status == TaskStatus.done) continue;

    final taskDate = DateTime(task.dateScheduled.year,
        task.dateScheduled.month, task.dateScheduled.day);
    if (taskDate != today) continue;

    // Parse do horário
    final timeParts = task.scheduledTime!.split(':');
    if (timeParts.length != 2) continue;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) continue;

    final scheduledDateTime =
        DateTime(now.year, now.month, now.day, hour, minute);

    // Só agenda se ainda não passou
    if (scheduledDateTime.isBefore(now)) continue;

    await _scheduleNotification(task, scheduledDateTime);
  }
}

  /// Agenda uma notificação para uma tarefa específica
  Future<bool> _scheduleNotification(Task task, DateTime scheduledTime) async {
    try {
      // Detalhes da notificação para Android
      // Usa som customizado de assets/sounds/notification.mp3 (copiado para res/raw/)
      const androidDetails = AndroidNotificationDetails(
        'task_notifications_v3',
        'Notificações de Tarefas',
        channelDescription: 'Notificações quando o horário de uma tarefa chega',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        icon: '@drawable/ic_notification',
        color: Color(0xFFFFD60A),
      );

      // Detalhes para iOS - usa som customizado de ios/Runner/Sounds/notification.aiff
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.aiff',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Converte para timezone local
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Agenda a notificação
      await _notifications.zonedSchedule(
        task.id,
        '⏰ Hora da Tarefa!',
        task.title,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );

      return true;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Mostra uma notificação imediatamente (para testes)
  Future<bool> showTestNotification() async {
    if (!_isInitialized) await init();

    try {
      // Usa configuração com som customizado
      const androidDetails = AndroidNotificationDetails(
        'task_notifications_v3',
        'Notificações de Tarefas',
        channelDescription: 'Notificações quando o horário de uma tarefa chega',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        icon: '@drawable/ic_notification',
        color: Color(0xFFFFD60A),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.aiff',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999, // ID fixo para teste
        '🔔 Teste de Notificação',
        'As notificações estão funcionando! ${DateTime.now()}',
        details,
      );

      return true;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Agenda uma notificação de teste para daqui a X segundos
  Future<bool> scheduleTestNotification(int seconds) async {
    if (!_isInitialized) await init();

    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'task_notifications_v3',
        'Notificações de Tarefas',
        channelDescription: 'Notificações quando o horário de uma tarefa chega',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        icon: '@drawable/ic_notification',
        color: Color(0xFFFFD60A),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.aiff',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        998, // ID fixo para teste agendado
        '⏰ Teste Agendado!',
        'Esta notificação foi agendada para $seconds segundos',
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_scheduled',
      );

      return true;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Lista notificações pendentes (para debug)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Cancela todas as notificações agendadas
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Libera recursos
  Future<void> dispose() async {
    await _notifications.cancelAll();
  }
}
