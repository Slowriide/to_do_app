import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';

class NoteCubit extends Cubit<List<Note>> {
  final NoteRepository repository;

  NoteCubit(this.repository) : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final notesList = await repository.getNotes();

    emit(notesList);
  }

  Future<void> addNote(String text, String title) async {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      text: text,
    );

    await repository.addNote(newNote);

    loadNotes();
  }

  Future<void> deleteNote(Note note) async {
    await repository.deleteNote(note);

    loadNotes();
  }

  Future<void> toggleCompletion(Note note) async {
    final updatedNote = note.toggleCompletion();

    await repository.updateNote(updatedNote);

    loadNotes();
  }

  Future<void> updateNote(Note updateNote) async {
    await repository.updateNote(updateNote);
    loadNotes();
  }
}
