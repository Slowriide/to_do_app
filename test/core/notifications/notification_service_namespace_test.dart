import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes;

  _FakeNoteRepository(this.notes);

  @override
  Future<void> addNote(Note newNote) async {}

  @override
  Future<void> deleteNote(Note note) async {}

  @override
  Future<Note?> getNoteById(int id) async => null;

  @override
  Future<List<Note>> getNotes() async => notes;

  @override
  Future<void> updateNote(Note note) async {}

  @override
  Future<void> updateNotes(List<Note> notes) async {}
}

class _FakeTodoRepository implements TodoRepository {
  final List<Todo> todos;

  _FakeTodoRepository(this.todos);

  @override
  Future<void> addSubTask(Todo subtask, int todoId) async {}

  @override
  Future<void> addTodo(Todo newTodo) async {}

  @override
  Future<void> deleteSubTask(Todo subtask) async {}

  @override
  Future<void> deleteTodo(Todo todo) async {}

  @override
  Future<Todo?> getTodoById(int id) async => null;

  @override
  Future<List<Todo>> getTodos() async => todos;

  @override
  Future<void> updateSubTask(Todo subtask) async {}

  @override
  Future<void> updateTodo(Todo todo) async {}

  @override
  Future<void> updateTodos(List<Todo> todos) async {}
}

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

void main() {
  test('notification IDs for note and todo do not collide for same entity id',
      () {
    final service = NotificationService();
    expect(service.notificationIdForNote(10),
        isNot(service.notificationIdForTodo(10)));
  });

  test('database reminder sync schedules note and todo with different IDs',
      () async {
    final now = DateTime.now();
    final service = _SpyNotificationService();

    await service.syncRemindersFromDatabase(
      noteRepository: _FakeNoteRepository([
        Note(
          id: 10,
          title: 'note',
          text: 'body',
          reminder: now.add(const Duration(minutes: 2)),
        ),
      ]),
      todoRepository: _FakeTodoRepository([
        Todo(
          id: 10,
          title: 'todo',
          isCompleted: false,
          subTasks: const [],
          isSubtask: false,
          order: 0,
          reminder: now.add(const Duration(minutes: 3)),
        ),
      ]),
    );

    expect(service.scheduledIds.length, 2);
    expect(service.scheduledIds[0], isNot(service.scheduledIds[1]));
    expect(service.scheduledIds[0], service.notificationIdForNote(10));
    expect(service.scheduledIds[1], service.notificationIdForTodo(10));
  });

  test('cancel helpers cancel note and todo with different IDs', () async {
    final service = _SpyNotificationService();

    await service.cancelNoteReminder(10);
    await service.cancelTodoReminder(10);

    expect(service.canceledIds, [
      service.notificationIdForNote(10),
      service.notificationIdForTodo(10),
    ]);
    expect(service.canceledIds[0], isNot(service.canceledIds[1]));
  });
}
