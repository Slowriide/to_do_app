import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

import '../../fake_repositories.dart';

class _SpyNotificationService extends NotificationService {
  final List<int> scheduledIds = [];
  final List<int> canceledIds = [];

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancelNotification(int id) async {
    canceledIds.add(id);
  }
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('NoteCubit reminder lifecycle schedules and cancels namespaced IDs', () async {
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

    await cubit.updateNote(note.copyWith(reminder: reminder.add(const Duration(hours: 1))));
    await cubit.updateNote(note.copyWith(reminder: null));
    await cubit.deleteNotes([note.copyWith(reminder: null)]);

    final noteNotificationId = notifications.notificationIdForNote(10);
    expect(notifications.scheduledIds.where((id) => id == noteNotificationId).length, 2);
    expect(notifications.canceledIds.where((id) => id == noteNotificationId).length, 2);
    await cubit.close();
  });

  test('TodoCubit reminder lifecycle schedules and cancels namespaced IDs', () async {
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

    await cubit.updateTodo(todo.copyWith(reminder: reminder.add(const Duration(hours: 1))));
    await cubit.updateTodo(todo.copyWith(reminder: null));
    await cubit.deleteTodo(todo.copyWith(reminder: null));

    final todoNotificationId = notifications.notificationIdForTodo(10);
    expect(notifications.scheduledIds.where((id) => id == todoNotificationId).length, 2);
    expect(notifications.canceledIds.where((id) => id == todoNotificationId).length, 2);
    await cubit.close();
  });
}
