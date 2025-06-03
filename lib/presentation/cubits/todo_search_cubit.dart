import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:to_do_app/domain/models/todo.dart';

/// Manages the search state for a list of Todo items.
///
/// Holds the complete list of todos and emits filtered results based on the search query.
class TodoSearchCubit extends Cubit<List<Todo>> {
  List<Todo> _todos;

  TodoSearchCubit(this._todos) : super(_todos);

  /// Updates the internal list of todos and emits the updated list.
  void updateTodos(List<Todo> todos) {
    _todos = todos;
    emit(_todos);
  }

  /// Filters the todos and their subtasks by the given search query
  /// and emits the filtered list.
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

  /// Clears the search filter and emits the full list of todos.
  void clearSearch() {
    emit(_todos);
  }
}
