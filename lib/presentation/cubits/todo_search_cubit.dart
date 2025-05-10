import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:to_do_app/domain/models/todo.dart';

class TodoSearchCubit extends Cubit<List<Todo>> {
  List<Todo> _todos;

  TodoSearchCubit(this._todos) : super(_todos);

  void updateTodos(List<Todo> todos) {
    _todos = todos;
    emit(_todos);
  }

  void search(String query) {
    final lowerQuery = query.toLowerCase();

    final filteredTodos = _todos
        .where(
          (todo) =>
              todo.subTasks.any((subtask) =>
                  subtask.title.toLowerCase().contains(lowerQuery)) ||
              todo.title.toLowerCase().contains(lowerQuery),
        )
        .toList();
    emit(filteredTodos);
  }

  void clearSearch() {
    emit(_todos);
  }
}
