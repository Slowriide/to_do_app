import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';

/// Cubit responsible for managing note search functionality.
///
/// Holds a list of all notes and emits filtered lists based on the search query.
/// Supports updating the notes list, searching by query, and clearing the search.
class NoteSearchCubit extends Cubit<List<Note>> {
  List<Note> _notes;

  NoteSearchCubit(this._notes) : super(_notes);

  /// Updates the internal notes list and emits the updated list.
  void updateNotes(List<Note> notes) {
    _notes = notes;
    emit(_notes);
  }

  /// Filters notes by the given query, matching either title or text (case-insensitive).
  void search(String query) {
    final lowerQuery = query.toLowerCase();

    final filteredNotes = _notes
        .where(
          (note) =>
              note.text.toLowerCase().contains(lowerQuery) ||
              note.title.toLowerCase().contains(lowerQuery),
        )
        .toList();
    emit(filteredNotes);
  }

  /// Clears the search and emits the full notes list.
  void clearSearch() {
    emit(_notes);
  }
}
