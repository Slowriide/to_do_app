import 'package:to_do_app/domain/models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes();

  Future<void> addNote(Note newNote);

  Future<void> updateNote(Note note);

  Future<void> deleteNote(Note note);
}
