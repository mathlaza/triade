import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';

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

  // Getter para saber se está habilitado
  bool get isEnabled => _isEnabled;

  /// Inicializa o serviço de notificações
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Inicializa timezone
      tz_data.initializeTimeZones();

      // Carrega preferência de notificações
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_enabledKey) ?? true;

      // Configurações para Android - usa ícone específico para notificações
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      // Configurações para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializa o plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicita permissão no Android 13+
      if (Platform.isAndroid) {
        await _requestAndroidPermission();
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Solicita permissão de notificação no Android 13+
  Future<void> _requestAndroidPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Callback quando usuário toca na notificação
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Aqui poderia navegar para a tarefa específica
  }

  /// Habilita ou desabilita notificações
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);

      if (!enabled) {
        // Cancela todas as notificações agendadas
        await _notifications.cancelAll();
      }
    } catch (e) {
      debugPrint('NotificationService setEnabled error: $e');
    }
  }

  /// Agenda notificações para todas as tarefas do dia com horário
  Future<void> scheduleTaskNotifications(List<Task> tasks) async {
    if (!_isEnabled || !_isInitialized) return;

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
  Future<void> _scheduleNotification(Task task, DateTime scheduledTime) async {
    try {
      // Detalhes da notificação para Android com som customizado
      const androidDetails = AndroidNotificationDetails(
        'task_notifications_v3', // Canal v3 com ícone correto
        'Notificações de Tarefas',
        channelDescription: 'Notificações quando o horário de uma tarefa chega',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        icon: '@drawable/ic_notification',
        fullScreenIntent: true, // Acorda a tela
      );

      // Detalhes para iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Converte para timezone local
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Agenda a notificação
      await _notifications.zonedSchedule(
        task.id, // ID único baseado no ID da tarefa
        '⏰ Hora da Tarefa!',
        task.title,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );

      debugPrint(
          'Scheduled notification for task ${task.id} at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Mostra uma notificação imediatamente (para testes)
  Future<void> showTestNotification() async {
    if (!_isInitialized) await init();

    // Usa o mesmo canal com som customizado
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
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🔔 Teste de Notificação',
      'As notificações estão funcionando!',
      details,
    );
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
