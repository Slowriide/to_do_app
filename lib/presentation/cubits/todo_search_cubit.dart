import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folder_filter_cubit.dart';

/// Manages the search state for a list of Todo items.
///
/// Holds the complete list of todos and emits filtered results based on the search query.
class TodoSearchCubit extends Cubit<List<Todo>> {
  List<Todo> _todos;
  String _query = '';
  FolderFilter _folderFilter = const FolderFilter.all();

  TodoSearchCubit(this._todos) : super(_todos);

  /// Updates the internal list of todos and emits the updated list.
  void updateTodos(List<Todo> todos) {
    _todos = todos;
    _emitFiltered();
  }

  /// Filters the todos and their subtasks by the given search query
  /// and emits the filtered list.
  void search(String query) {
    _query = query.toLowerCase();
    _emitFiltered();
  }

  /// Clears the search filter and emits the full list of todos.
  void clearSearch() {
    _query = '';
    _emitFiltered();
  }

  void setFolderFilter(FolderFilter filter) {
    _folderFilter = filter;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = _todos.where((todo) {
      final matchesQuery = todo.title.toLowerCase().contains(_query) ||
          todo.subTasks.any(
            (subtask) => subtask.title.toLowerCase().contains(_query),
          );
      if (!matchesQuery) return false;

      switch (_folderFilter.type) {
        case FolderFilterType.all:
          return true;
        case FolderFilterType.inbox:
          return todo.folderId == null;
        case FolderFilterType.custom:
          return todo.folderId == _folderFilter.folderId;
      }
    }).toList();
    emit(filtered);
  }
}
