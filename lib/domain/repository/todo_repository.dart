import 'package:to_do_app/domain/models/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<void> addTodo(Todo newTodo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(Todo todo);
  Future<void> addSubTask(Todo subtask, int todoId);
  Future<void> updateSubTask(Todo subtask);
  Future<void> deleteSubTask(Todo subtask);
}
