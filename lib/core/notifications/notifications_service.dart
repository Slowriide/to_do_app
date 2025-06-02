import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInit = false;

  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> init() async {
    if (_isInit) return;

    _requestPermissions();
    tz.initializeTimeZones();

    final androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final String timeZoneName = await FlutterTimezone.getLocalTimezone();

    final initSettings = InitializationSettings(android: androidInitSettings);

    tz.setLocalLocation(tz.getLocation(timeZoneName));

    await _notificationsPlugin.initialize(initSettings);

    _isInit = true;
  }

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
    await _notificationsPlugin.cancel(id);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails(),
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

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
