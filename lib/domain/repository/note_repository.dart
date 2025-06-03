import 'package:to_do_app/domain/models/note.dart';

/// Abstract repository contract for managing [Note] entities.
///
/// Defines the operations related to retrieving, adding,
/// updating, and deleting notes in the data source.
abstract class NoteRepository {
  Future<List<Note>> getNotes();

  Future<void> addNote(Note newNote);

  Future<void> updateNote(Note note);

  Future<void> deleteNote(Note note);
}
