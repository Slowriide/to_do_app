import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Manages local notifications in a Flutter app.
///
/// Provides initialization, permission handling, and scheduling or canceling
/// notifications using [flutter_local_notifications] and [timezone].
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const int _maxSigned32Bit = 0x7fffffff;

  bool _isInit = false;

  /// Private constructor to ensure singleton pattern
  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Initializes the notification service and configures timezone and permissions.
  ///
  /// This method must be called before showing any notifications.
  Future<void> init() async {
    if (_isInit) return;

    await _requestPermissions();
    tz.initializeTimeZones();

    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInitSettings = DarwinInitializationSettings();

    final timeZone = await FlutterTimezone.getLocalTimezone();

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
      macOS: darwinInitSettings,
    );

    tz.setLocalLocation(tz.getLocation(timeZone.identifier));

    await _notificationsPlugin.initialize(settings: initSettings);

    _isInit = true;
  }

  /// Builds the default [NotificationDetails] for Android.
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  /// Schedules a notification for the specified [scheduledDate].
  ///
  /// If the date is not in the future, no notification is shown.
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    final notificationId = _normalizeNotificationId(id);
    final now = DateTime.now();

    if (!scheduledDate.isAfter(now)) {
      return;
    }
    await _notificationsPlugin.cancel(id: notificationId);

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
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
    await _notificationsPlugin.cancel(id: _normalizeNotificationId(id));
  }

  int notificationIdForNote(int id) => _normalizeNotificationId((id * 2));

  int notificationIdForTodo(int id) => _normalizeNotificationId((id * 2) + 1);

  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    await showNotification(
      id: notificationIdForNote(noteId),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> scheduleTodoReminder({
    required int todoId,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    await showNotification(
      id: notificationIdForTodo(todoId),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> cancelNoteReminder(int noteId) async {
    await cancelNotification(notificationIdForNote(noteId));
  }

  Future<void> cancelTodoReminder(int todoId) async {
    await cancelNotification(notificationIdForTodo(todoId));
  }

  /// Cancels all scheduled and shown notifications for this app.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Re-schedules future reminders from persisted notes and todos.
  Future<void> syncRemindersFromDatabase({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    final now = DateTime.now();
    final notes = await noteRepository.getNotes();
    for (final note in notes) {
      final reminder = note.reminder;
      if (reminder == null || !reminder.isAfter(now)) continue;
      await scheduleNoteReminder(
        noteId: note.id,
        title: note.title,
        body: note.text,
        scheduledDate: reminder,
      );
    }

    final todos = await todoRepository.getTodos();
    for (final todo in todos) {
      final reminder = todo.reminder;
      if (reminder == null || !reminder.isAfter(now)) continue;
      await scheduleTodoReminder(
        todoId: todo.id,
        title: todo.title,
        scheduledDate: reminder,
      );
    }
  }

  int _normalizeNotificationId(int rawId) {
    var normalized = rawId & _maxSigned32Bit;
    if (normalized == 0) {
      normalized = 1;
    }
    return normalized;
  }
}
