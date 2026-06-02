// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    // تهيئة بيانات المناطق الزمنية
    tz_data.initializeTimeZones();
    // تعيين المنطقة الزمنية المحلية (يمكن تعديلها حسب الحاجة)
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); // أو أي منطقة زمنية مناسبة
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'accounting_ledger_channel',
      'Accounting Ledger',
      channelDescription: 'Accounting Ledger notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// جدولة إشعار متكرر يومياً في وقت محدد (ساعة ودقيقة)
  static Future<void> scheduleDailyRecurringNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
  }) async {
    await initialize();

    // الحصول على الوقت الحالي في المنطقة الزمنية المحلية
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    
    // إذا كان الوقت المحدد قد مضى اليوم، نجدوله للغد
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'accounting_ledger_recurring',
      'Recurring Reminders',
      channelDescription: 'Reminders for recurring transactions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime, // الآن من النوع TZDateTime
      details,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  static Future<void> notifyInstallmentDue(
      String installmentName, double amount, String currency) async {
    await showNotification(
      id: AppConstants.installmentNotificationId,
      title: 'Installment Due',
      body: '$installmentName: $currency ${amount.toStringAsFixed(2)}',
    );
  }

  static Future<void> notifyRecurringTransaction(
      String description, double amount, String currency) async {
    await showNotification(
      id: AppConstants.recurringNotificationId,
      title: 'Recurring Transaction',
      body: '$description: $currency ${amount.toStringAsFixed(2)}',
    );
  }
}
