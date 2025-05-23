import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';

class NoteCubit extends Cubit<List<Note>> {
  final NoteRepository repository;

  NoteCubit(this.repository) : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final notesList = await repository.getNotes();

    //order pinned
    final sortedNotes = [...notesList]..sort(
        (a, b) {
          if (a.isPinned == b.isPinned) return 0;
          return a.isPinned ? -1 : 1;
        },
      );

    emit(sortedNotes);
  }

  Future<void> addNote(String text, String title,
      {DateTime? reminder, required int id}) async {
    final newNote = Note(
      id: id,
      title: title,
      text: text,
      reminder: reminder,
    );

    await repository.addNote(newNote);

    loadNotes();
  }

  Future<void> deleteNote(Note note) async {
    await repository.deleteNote(note);
    NotificationService().cancelNotification(note.id);
    loadNotes();
  }

  Future<void> deleteMultiples(List<Note> notesToDelete) async {
    for (final note in notesToDelete) {
      await repository.deleteNote(note);
      NotificationService().cancelNotification(note.id);
    }
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

    if (updateNote.reminder != null) {
      NotificationService().showNotification(
        id: updateNote.id,
        title: updateNote.title,
        body: updateNote.text,
        scheduledDate: updateNote.reminder!,
      );
    }
  }

  Future<void> updateNotes(List<Note> notes) async {
    for (final note in notes) {
      await repository.updateNote(note);
      if (note.reminder != null) {
        NotificationService().showNotification(
          id: note.id,
          title: note.title,
          body: note.text,
          scheduledDate: note.reminder!,
        );
      }
    }
    loadNotes();
  }
}
