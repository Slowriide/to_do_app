import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';

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
class TodoCubit extends Cubit<TodoState> {
  final TodoRepository repository;
  // TodoFilter _currentFilter = TodoFilter.all;

  TodoCubit(this.repository) : super(const TodoState.loading()) {
    loadTodos();
  }

  /// Loads the list of todos from the repository and emits
  /// the list sorted by pinned status.
  Future<void> loadTodos() async {
    emit(TodoState.loading(state.todos));
    try {
      final todosList = await repository.getTodos();

      final sortedTodos = [...todosList]..sort(
          (a, b) {
            if (a.isPinned == b.isPinned) return a.order.compareTo(b.order);
            return a.isPinned ? -1 : 1;
          },
        );

      emit(TodoState.success(sortedTodos));
    } catch (e) {
      emit(TodoState.error('Failed to load todos', state.todos));
    }
  }

  /// Adds a new todo with given title, subtasks, optional reminder, and id.
  ///
  /// Then reloads the todos list.
  Future<void> addTodo(String title, List<Todo> subtasks,
      {DateTime? reminder, required int id, int? folderId}) async {
    final currentTodos = state.todos;
    final nextOrder = currentTodos.isEmpty
        ? 0
        : currentTodos.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1;
    final newTodo = Todo(
      id: id,
      title: title,
      isCompleted: false,
      subTasks: subtasks,
      isSubtask: false,
      order: nextOrder,
      reminder: reminder,
      folderId: folderId,
    );
    await repository.addTodo(newTodo);
    await loadTodos();
  }

  /// Deletes the given todo and cancels its notification.
  ///
  /// Then reloads the todos list.
  Future<void> deleteTodo(Todo todo) async {
    await repository.deleteTodo(todo);
    await loadTodos();
    await NotificationService().cancelNotification(todo.id);
  }

  /// Updates the given todo and reloads the list.
  ///
  /// If the todo has a reminder, schedules a notification.
  Future<void> updateTodo(Todo todo) async {
    await repository.updateTodo(todo);
    await loadTodos();
    if (todo.reminder != null) {
      await NotificationService().showNotification(
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
    await repository.updateTodos(todos);
    for (final todo in todos) {
      if (todo.reminder == null) continue;
      await NotificationService().showNotification(
        id: todo.id,
        title: todo.title,
        scheduledDate: todo.reminder!,
      );
    }
    await loadTodos();
  }

  /// Toggles completion state of a todo, updates it, and reloads the list.
  Future<void> toggleCompletion(Todo todo) async {
    final updatedTodo = todo.toggleCompletition();
    await repository.updateTodo(updatedTodo);
    await loadTodos();
  }

  /// Deletes multiple todos and cancels their notifications.
  Future<void> deleteMultiples(List<Todo> todosToDelete) async {
    for (final todo in todosToDelete) {
      await repository.deleteTodo(todo);
      await NotificationService().cancelNotification(todo.id);
    }
    await loadTodos();
  }

  /// Updates a subtask and reloads the list.
  Future<void> updateSubtask(Todo subtask) async {
    await repository.updateSubTask(subtask);
    await loadTodos();
  }

  /// Reorders todos based on the UI order and persists it.
  Future<void> reorderTodos(List<Todo> orderedTodos) async {
    final reordered =
        List<Todo>.generate(orderedTodos.length, (i) => orderedTodos[i].copyWith(order: i));
    await repository.updateTodos(reordered);
    await loadTodos();
  }

  /// Reorders todos by dragged and target ids.
  ///
  /// Reordering is constrained to todos within the same pin group so that
  /// pinned/unpinned sort behavior remains predictable.
  Future<void> reorderTodoByIds(int draggedId, int targetId) async {
    final todos = [...state.todos];
    final from = todos.indexWhere((t) => t.id == draggedId);
    final to = todos.indexWhere((t) => t.id == targetId);

    if (from < 0 || to < 0 || from == to) return;
    if (todos[from].isPinned != todos[to].isPinned) return;

    final moved = todos.removeAt(from);
    todos.insert(to, moved);

    final reordered = List<Todo>.generate(
      todos.length,
      (i) => todos[i].copyWith(order: i),
    );
    await repository.updateTodos(reordered);
    await loadTodos();
  }

  Future<void> moveTodosToFolder(List<int> todoIds, int? folderId) async {
    final selected =
        state.todos.where((todo) => todoIds.contains(todo.id)).toList();
    for (final todo in selected) {
      await repository.updateTodo(todo.copyWith(folderId: folderId));
    }
    await loadTodos();
  }

  Future<void> archiveTodos(List<Todo> todos) async {
    if (todos.isEmpty) return;
    final toArchiveIds = todos.map((todo) => todo.id).toSet();

    final archivedState = state.todos
        .map((todo) => toArchiveIds.contains(todo.id)
            ? todo.copyWith(isArchived: true, isPinned: false)
            : todo)
        .toList();

    final reflowed = _reflowActiveTodos(archivedState);
    await repository.updateTodos(reflowed);
    await loadTodos();
  }

  Future<void> restoreTodos(List<Todo> todos) async {
    if (todos.isEmpty) return;
    final toRestoreIds = todos.map((todo) => todo.id).toSet();
    final restoredState = state.todos
        .map((todo) =>
            toRestoreIds.contains(todo.id) ? todo.copyWith(isArchived: false) : todo)
        .toList();

    final reflowed = _reflowActiveTodos(restoredState);
    await repository.updateTodos(reflowed);
    await loadTodos();
  }

  List<Todo> _reflowActiveTodos(List<Todo> todos) {
    final active = todos.where((todo) => !todo.isArchived).toList()
      ..sort((a, b) {
        if (a.isPinned == b.isPinned) return a.order.compareTo(b.order);
        return a.isPinned ? -1 : 1;
      });

    final activeById = {
      for (var i = 0; i < active.length; i++) active[i].id: active[i].copyWith(order: i),
    };

    return todos.map((todo) => activeById[todo.id] ?? todo).toList();
  }
}
