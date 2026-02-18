import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';

/// Cubit responsible for managing note search functionality.
///
/// Holds a list of all notes and emits filtered lists based on the search query.
/// Supports updating the notes list, searching by query, and clearing the search.
class NoteSearchCubit extends Cubit<List<Note>> {
  List<Note> _notes;
  String _query = '';
  FolderFilter _folderFilter = const FolderFilter.all();

  NoteSearchCubit(this._notes) : super(_notes);

  /// Updates the internal notes list and emits the updated list.
  void updateNotes(List<Note> notes) {
    _notes = notes;
    _emitFiltered();
  }

  /// Filters notes by the given query, matching either title or text (case-insensitive).
  void search(String query) {
    _query = query.toLowerCase();
    _emitFiltered();
  }

  /// Clears the search and emits the full notes list.
  void clearSearch() {
    _query = '';
    _emitFiltered();
  }

  void setFolderFilter(FolderFilter filter) {
    _folderFilter = filter;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = _notes.where((note) {
      final matchesQuery = note.text.toLowerCase().contains(_query) ||
          note.title.toLowerCase().contains(_query);
      if (!matchesQuery) return false;

      switch (_folderFilter.type) {
        case FolderFilterType.all:
          return true;
        case FolderFilterType.inbox:
          return note.folderId == null;
        case FolderFilterType.custom:
          return note.folderId == _folderFilter.folderId;
      }
    }).toList();
    emit(filtered);
  }
}
