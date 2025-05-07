import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';

class NoteSearchCubit extends Cubit<List<Note>> {
  List<Note> _notes;

  NoteSearchCubit(this._notes) : super(_notes);

  void updateNotes(List<Note> notes) {
    _notes = notes;
    emit(_notes);
  }

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

  void clearSearch() {
    emit(_notes);
  }
}
