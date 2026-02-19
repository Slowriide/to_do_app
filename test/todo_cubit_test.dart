import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';

class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository(this._todos);

  List<Todo> _todos;
  int updateTodoCalls = 0;
  int updateTodosCalls = 0;

  @override
  Future<void> addSubTask(Todo subtask, int todoId) async {}

  @override
  Future<void> addTodo(Todo newTodo) async {
    _todos = [..._todos, newTodo];
  }

  @override
  Future<void> deleteSubTask(Todo subtask) async {}

  @override
  Future<void> deleteTodo(Todo todo) async {
    _todos = _todos.where((t) => t.id != todo.id).toList();
  }

  @override
  Future<List<Todo>> getTodos() async => List<Todo>.from(_todos);

  @override
  Future<void> updateSubTask(Todo subtask) async {}

  @override
  Future<void> updateTodo(Todo todo) async {
    updateTodoCalls++;
    _todos = _todos.map((t) => t.id == todo.id ? todo : t).toList();
  }

  @override
  Future<void> updateTodos(List<Todo> todos) async {
    updateTodosCalls++;
    final byId = {for (final t in todos) t.id: t};
    _todos = _todos.map((t) => byId[t.id] ?? t).toList();
  }
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('loads todos sorted with pinned first then by order', () async {
    final repo = FakeTodoRepository([
      Todo(
        id: 1,
        title: 'b',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 2,
        isPinned: false,
      ),
      Todo(
        id: 2,
        title: 'a',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 1,
        isPinned: true,
      ),
      Todo(
        id: 3,
        title: 'c',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
        isPinned: false,
      ),
    ]);
    final cubit = TodoCubit(repo);

    await _settle();

    expect(cubit.state.status, TodoStatus.success);
    expect(cubit.state.todos.map((t) => t.id).toList(), [2, 3, 1]);
    await cubit.close();
  });

  test('reorderTodos persists in a single batch update', () async {
    final repo = FakeTodoRepository([
      Todo(
        id: 1,
        title: 'a',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
      ),
      Todo(
        id: 2,
        title: 'b',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 1,
      ),
      Todo(
        id: 3,
        title: 'c',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 2,
      ),
    ]);
    final cubit = TodoCubit(repo);
    await _settle();

    await cubit
        .reorderTodos([cubit.state.todos[2], cubit.state.todos[0], cubit.state.todos[1]]);

    expect(repo.updateTodosCalls, 1);
    expect(repo.updateTodoCalls, 0);
    expect(cubit.state.todos.map((t) => t.id).toList(), [3, 1, 2]);
    expect(cubit.state.todos.map((t) => t.order).toList(), [0, 1, 2]);
    await cubit.close();
  });

  test('reorderTodoByIds ignores movement across pin groups', () async {
    final repo = FakeTodoRepository([
      Todo(
        id: 1,
        title: 'pinned',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
        isPinned: true,
      ),
      Todo(
        id: 2,
        title: 'normal',
        isCompleted: false,
        subTasks: const [],
        isSubtask: false,
        order: 0,
      ),
    ]);
    final cubit = TodoCubit(repo);
    await _settle();

    final before = cubit.state.todos.map((t) => t.id).toList();
    await cubit.reorderTodoByIds(1, 2);

    expect(repo.updateTodosCalls, 0);
    expect(cubit.state.todos.map((t) => t.id).toList(), before);
    await cubit.close();
  });
}
