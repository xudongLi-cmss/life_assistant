import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 检查通知功能是否可用
  static bool get isSupported => !kIsWeb;

  // 初始化通知服务
  static Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // 请求权限
      final prefs = await SharedPreferences.getInstance();
      final permissionsRequested = prefs.getBool('notification_permissions_requested') ?? false;

      if (!permissionsRequested) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        await prefs.setBool('notification_permissions_requested', true);
      }

      _initialized = true;
    } catch (e) {
      // 忽略初始化错误
      print('NotificationService initialization failed: $e');
    }
  }

  // 通知点击回调
  static void _onNotificationTap(NotificationResponse response) {
    // 处理通知点击事件
    // 可以导航到详情页面
  }

  // 安排待办事项提醒
  static Future<void> scheduleTodoReminder(TodoItem todo) async {
    if (!isSupported || !todo.reminderEnabled || todo.reminderTime == null) return;

    try {
      // 将String ID转换为int（使用hashCode）
      final notificationId = todo.id.hashCode;

      await _plugin.zonedSchedule(
        notificationId,
        todo.title,
        todo.reminderContent ?? todo.description,
        _nextInstanceOfTime(todo.reminderTime!),
        _notificationDetails(todo.reminderMethod),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // 忽略通知设置失败
      print('Failed to schedule notification: $e');
    }
  }

  // 取消待办事项提醒
  static Future<void> cancelTodoReminder(String todoId) async {
    if (!isSupported) return;

    try {
      final notificationId = todoId.hashCode;
      await _plugin.cancel(notificationId);
    } catch (e) {
      print('Failed to cancel notification: $e');
    }
  }

  // 取消所有提醒
  static Future<void> cancelAllReminders() async {
    if (!isSupported) return;

    try {
      await _plugin.cancelAll();
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }

  // 立即显示通知（用于测试）
  static Future<void> showImmediateNotification(
    String title,
    String body,
  ) async {
    if (!isSupported) return;

    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        _notificationDetails(ReminderMethod.notification),
      );
    } catch (e) {
      print('Failed to show immediate notification: $e');
    }
  }

  // 通知详情配置
  static NotificationDetails _notificationDetails(ReminderMethod method) {
    final androidDetails = AndroidNotificationDetails(
      'todo_reminders',
      '待办事项提醒',
      channelDescription: '待办事项提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: method == ReminderMethod.vibration ||
          method == ReminderMethod.soundAndVibration,
      playSound: method == ReminderMethod.sound ||
          method == ReminderMethod.soundAndVibration,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // 获取下一次提醒时间
  static tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, time.year, time.month, time.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // 获取活动通知
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!isSupported) return [];

    try {
      return await _plugin.getActiveNotifications();
    } catch (e) {
      print('Failed to get active notifications: $e');
      return [];
    }
  }

  // 获取待发送的通知
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!isSupported) return [];

    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      print('Failed to get pending notifications: $e');
      return [];
    }
  }
}
