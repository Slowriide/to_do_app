import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';

enum ArchiveScope { activeOnly, archivedOnly }

/// Cubit responsible for managing note search functionality.
///
/// Holds a list of all notes and emits filtered lists based on the search query.
/// Supports updating the notes list, searching by query, and clearing the search.
class NoteSearchCubit extends Cubit<List<Note>> {
  List<Note> _notes;
  String _query = '';
  FolderFilter _folderFilter = const FolderFilter.all();
  ArchiveScope _archiveScope = ArchiveScope.activeOnly;

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

  void setArchiveScope(ArchiveScope scope) {
    _archiveScope = scope;
    _emitFiltered();
  }

  void _emitFiltered() {
    final filtered = _notes.where((note) {
      final matchesArchive = _archiveScope == ArchiveScope.activeOnly
          ? !note.isArchived
          : note.isArchived;
      if (!matchesArchive) return false;

      final matchesQuery = note.text.toLowerCase().contains(_query) ||
          note.title.toLowerCase().contains(_query);
      if (!matchesQuery) return false;

      switch (_folderFilter.type) {
        case FolderFilterType.all:
          return true;
        case FolderFilterType.custom:
          final selectedFolderId = _folderFilter.folderId;
          if (selectedFolderId == null) return false;
          return note.folderIds.contains(selectedFolderId);
      }
    }).toList();
    emit(filtered);
  }
}
