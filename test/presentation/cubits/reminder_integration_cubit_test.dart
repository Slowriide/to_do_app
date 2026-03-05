import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

import '../../fake_repositories.dart';
import '../../test_utils/plugin_mocks.dart';

class _SpyNotificationService extends NotificationService {
  final List<int> scheduledIds = [];
  final List<int> canceledIds = [];

  @override
  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    scheduledIds.add(notificationIdForNote(noteId));
  }

  @override
  Future<void> scheduleTodoReminder({
    required int todoId,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    scheduledIds.add(notificationIdForTodo(todoId));
  }

  @override
  Future<void> cancelNoteReminder(int noteId) async {
    canceledIds.add(notificationIdForNote(noteId));
  }

  @override
  Future<void> cancelTodoReminder(int todoId) async {
    canceledIds.add(notificationIdForTodo(todoId));
  }
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUpHomeWidgetMocks();

  test('NoteCubit reminder lifecycle schedules and cancels namespaced IDs',
      () async {
    final notifications = _SpyNotificationService();
    final cubit = NoteCubit(
      FakeNoteRepository(),
      notificationService: notifications,
    );
    await _settle();

    final reminder = DateTime.now().add(const Duration(hours: 1));
    await cubit.addNote(
      'body',
      'title',
      id: 10,
      reminder: reminder,
    );
    final note = cubit.state.notes.firstWhere((n) => n.id == 10);

    await cubit.updateNote(
        note.copyWith(reminder: reminder.add(const Duration(hours: 1))));
    await cubit.updateNote(note.copyWith(reminder: null));
    await cubit.deleteNotes([note.copyWith(reminder: null)]);

    final noteNotificationId = notifications.notificationIdForNote(10);
    expect(
        notifications.scheduledIds
            .where((id) => id == noteNotificationId)
            .length,
        2);
    expect(
        notifications.canceledIds
            .where((id) => id == noteNotificationId)
            .length,
        2);
    await cubit.close();
  });

  test('TodoCubit reminder lifecycle schedules and cancels namespaced IDs',
      () async {
    final notifications = _SpyNotificationService();
    final cubit = TodoCubit(
      FakeTodoRepository(),
      notificationService: notifications,
    );
    await _settle();

    final reminder = DateTime.now().add(const Duration(hours: 1));
    await cubit.addTodo(
      'todo',
      const <Todo>[],
      id: 10,
      reminder: reminder,
    );
    final todo = cubit.state.todos.firstWhere((t) => t.id == 10);

    await cubit.updateTodo(
        todo.copyWith(reminder: reminder.add(const Duration(hours: 1))));
    await cubit.updateTodo(todo.copyWith(reminder: null));
    await cubit.deleteTodo(todo.copyWith(reminder: null));

    final todoNotificationId = notifications.notificationIdForTodo(10);
    expect(
        notifications.scheduledIds
            .where((id) => id == todoNotificationId)
            .length,
        2);
    expect(
        notifications.canceledIds
            .where((id) => id == todoNotificationId)
            .length,
        2);
    await cubit.close();
  });

  test(
      'NoteCubit past reminder does not schedule and cancels existing reminder slot',
      () async {
    final notifications = _SpyNotificationService();
    final cubit = NoteCubit(
      FakeNoteRepository(),
      notificationService: notifications,
    );
    await _settle();

    await cubit.addNote(
      'body',
      'title',
      id: 20,
      reminder: DateTime(2000, 1, 1),
    );

    final noteNotificationId = notifications.notificationIdForNote(20);
    expect(notifications.scheduledIds.where((id) => id == noteNotificationId),
        isEmpty);
    expect(
      notifications.canceledIds.where((id) => id == noteNotificationId).length,
      1,
    );
    await cubit.close();
  });

  test(
      'TodoCubit past reminder does not schedule and cancels existing reminder slot',
      () async {
    final notifications = _SpyNotificationService();
    final cubit = TodoCubit(
      FakeTodoRepository(),
      notificationService: notifications,
    );
    await _settle();

    await cubit.addTodo(
      'todo',
      const <Todo>[],
      id: 20,
      reminder: DateTime(2000, 1, 1),
    );

    final todoNotificationId = notifications.notificationIdForTodo(20);
    expect(notifications.scheduledIds.where((id) => id == todoNotificationId),
        isEmpty);
    expect(
      notifications.canceledIds.where((id) => id == todoNotificationId).length,
      1,
    );
    await cubit.close();
  });
}
