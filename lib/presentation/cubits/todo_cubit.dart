import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

enum TodoFilter {
  all,
  completed,
  incomplete,
}

class TodoCubit extends Cubit<List<Todo>> {
  final TodoRepository repository;
  // TodoFilter _currentFilter = TodoFilter.all;

  TodoCubit(this.repository) : super([]) {
    loadTodos();
  }

  // void setFilter(TodoFilter filter) {
  //   _currentFilter = filter;
  //   loadTodos();
  // }

  Future<void> loadTodos() async {
    final todosList = await repository.getTodos();

    emit(todosList);
  }

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

  Future<void> deleteTodo(Todo todo) async {
    await repository.deleteTodo(todo);
    loadTodos();
    NotificationService().cancelNotification(todo.id);
  }

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

  Future<void> toggleCompletion(Todo todo) async {
    final updatedTodo = todo.toggleCompletition();
    await repository.updateTodo(updatedTodo);
    loadTodos();
  }

  Future<void> addSubtask(Todo subtasks, int todoId) async {
    await repository.addSubTask(subtasks, todoId);
    loadTodos();
  }

  Future<void> deleteSubtask(Todo subtasks) async {
    await repository.deleteSubTask(subtasks);
    loadTodos();
  }

  Future<void> updateSubtask(Todo subtask) async {
    await repository.updateSubTask(subtask);
    loadTodos();
  }
}
