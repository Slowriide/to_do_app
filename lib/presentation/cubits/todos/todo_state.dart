import 'package:to_do_app/domain/models/todo.dart';

enum TodoStatus { loading, success, error }

class TodoState {
  final TodoStatus status;
  final List<Todo> todos;
  final String? errorMessage;

  const TodoState({
    required this.status,
    required this.todos,
    this.errorMessage,
  });

  const TodoState.loading([List<Todo> todos = const []])
      : this(status: TodoStatus.loading, todos: todos);

  const TodoState.success(List<Todo> todos)
      : this(status: TodoStatus.success, todos: todos);

  const TodoState.error(String message, [List<Todo> todos = const []])
      : this(
          status: TodoStatus.error,
          todos: todos,
          errorMessage: message,
        );
}
