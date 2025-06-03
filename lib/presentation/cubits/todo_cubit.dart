import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

enum TodoFilter {
  all,
  completed,
  incomplete,
}

/// Cubit responsible for managing the state of the Todo list.
///
/// Handles loading, adding, updating, deleting todos and subtasks,
/// toggling completion status, and scheduling notifications when reminders exist.
///
/// The state is a list of Todo objects, automatically sorted by pinned status.
class TodoCubit extends Cubit<List<Todo>> {
  final TodoRepository repository;
  // TodoFilter _currentFilter = TodoFilter.all;

  TodoCubit(this.repository) : super([]) {
    loadTodos();
  }

  /// Loads the list of todos from the repository and emits
  /// the list sorted by pinned status.
  Future<void> loadTodos() async {
    final todosList = await repository.getTodos();

    final sortedTodos = [...todosList]..sort(
        (a, b) {
          if (a.isPinned == b.isPinned) return 0;
          return a.isPinned ? -1 : 1;
        },
      );

    emit(sortedTodos);
  }

  /// Adds a new todo with given title, subtasks, optional reminder, and id.
  ///
  /// Then reloads the todos list.
  Future<void> addTodo(String title, List<Todo> subtasks,
      {DateTime? reminder, required int id}) async {
    final newTodo = Todo(
      id: id,
      title: title,
      isCompleted: false,
      subTasks: subtasks,
      isSubtask: false,
      order: 0,
      reminder: reminder,
    );
    await repository.addTodo(newTodo);
    loadTodos();
  }

  /// Deletes the given todo and cancels its notification.
  ///
  /// Then reloads the todos list.
  Future<void> deleteTodo(Todo todo) async {
    await repository.deleteTodo(todo);
    loadTodos();
    NotificationService().cancelNotification(todo.id);
  }

  /// Updates the given todo and reloads the list.
  ///
  /// If the todo has a reminder, schedules a notification.
  Future<void> updateTodo(Todo todo) async {
    await repository.updateTodo(todo);
    loadTodos();
    if (todo.reminder != null) {
      NotificationService().showNotification(
        id: todo.id,
        title: todo.title,
        scheduledDate: todo.reminder!,
      );
    }
  }

  /// Updates a list of todos and reloads the list.
  ///
  /// Also schedules notifications for todos with reminders.
  Future<void> updateTodos(List<Todo> todos) async {
    for (final todo in todos) {
      await repository.updateTodo(todo);
      if (todo.reminder != null) {
        NotificationService().showNotification(
          id: todo.id,
          title: todo.title,
          scheduledDate: todo.reminder!,
        );
      }
    }
    await loadTodos();
  }

  /// Toggles completion state of a todo, updates it, and reloads the list.
  Future<void> toggleCompletion(Todo todo) async {
    final updatedTodo = todo.toggleCompletition();
    await repository.updateTodo(updatedTodo);
    loadTodos();
  }

  /// Deletes multiple todos and cancels their notifications.
  Future<void> deleteMultiples(List<Todo> todosToDelete) async {
    for (final todo in todosToDelete) {
      await repository.deleteTodo(todo);
      NotificationService().cancelNotification(todo.id);
    }
    loadTodos();
  }

  /// Updates a subtask and reloads the list.
  Future<void> updateSubtask(Todo subtask) async {
    await repository.updateSubTask(subtask);
    loadTodos();
  }
}
