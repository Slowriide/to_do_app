import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Manages local notifications in a Flutter app.
///
/// Provides initialization, permission handling, and scheduling or canceling
/// notifications using [flutter_local_notifications] and [timezone].
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInit = false;

  /// Private constructor to ensure singleton pattern
  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Initializes the notification service and configures timezone and permissions.
  ///
  /// This method must be called before showing any notifications.
  Future<void> init() async {
    if (_isInit) return;

    await _requestPermissions();
    tz.initializeTimeZones();

    final androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final timeZone = await FlutterTimezone.getLocalTimezone();

    final initSettings = InitializationSettings(android: androidInitSettings);

    tz.setLocalLocation(tz.getLocation(timeZone.identifier));

    await _notificationsPlugin.initialize(settings: initSettings);

    _isInit = true;
  }

  /// Builds the default [NotificationDetails] for Android.
  NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
    );
  }

  /// Schedules a notification for the specified [scheduledDate].
  ///
  /// If the date is in the past, no notification is shown.
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) {
      return;
    }
    await _notificationsPlugin.cancel(id: id);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'payload',
    );
  }

  // Future<void> checkPendingNotifications() async {
  //   final List<PendingNotificationRequest> pendingNotifications =
  //       await _notificationsPlugin.pendingNotificationRequests();

  //   for (var notification in pendingNotifications) {
  //     print(
  //       'Pending Notification: ${notification.id}, hora: ${notification.title}',
  //     );
  //   }
  // }

  /// Cancels a notification with the given [id], if any exists.
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
