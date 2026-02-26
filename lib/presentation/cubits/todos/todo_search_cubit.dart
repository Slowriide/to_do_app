import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';

enum TodoArchiveScope { activeOnly, archivedOnly }

/// Manages the search state for a list of Todo items.
///
/// Holds the complete list of todos and emits filtered results based on the search query.
class TodoSearchCubit extends Cubit<List<Todo>> {
  List<Todo> _todos;
  String _query = '';
  FolderFilter _folderFilter = const FolderFilter.all();
  Set<int>? _folderScopeIds;
  TodoArchiveScope _archiveScope = TodoArchiveScope.activeOnly;

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

  void setFolderFilter(FolderFilter filter, {Set<int>? folderScopeIds}) {
    _folderFilter = filter;
    _folderScopeIds = folderScopeIds;
    _emitFiltered();
  }

  void setArchiveScope(TodoArchiveScope scope) {
    _archiveScope = scope;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = _todos.where((todo) {
      final matchesArchive = _archiveScope == TodoArchiveScope.activeOnly
          ? !todo.isArchived
          : todo.isArchived;
      if (!matchesArchive) return false;

      final matchesQuery = todo.title.toLowerCase().contains(_query) ||
          todo.subTasks.any(
            (subtask) => subtask.title.toLowerCase().contains(_query),
          );
      if (!matchesQuery) return false;

      switch (_folderFilter.type) {
        case FolderFilterType.all:
          return true;
        case FolderFilterType.custom:
          final scope = _folderScopeIds;
          if (scope == null || scope.isEmpty) {
            final selectedFolderId = _folderFilter.folderId;
            if (selectedFolderId == null) return false;
            return todo.folderIds.contains(selectedFolderId);
          }
          return todo.folderIds.any(scope.contains);
      }
    }).toList();
    emit(filtered);
  }
}
