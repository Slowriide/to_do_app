import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';

/// Cubit that manages the list of notes.
///
/// Loads notes from the repository and emits updated lists.
///
/// Supports adding, deleting (single and multiple), updating, and toggling completion of notes.
///
/// Handles scheduling and canceling notifications based on note reminders.
class NoteCubit extends Cubit<List<Note>> {
  final NoteRepository repository;

  NoteCubit(this.repository) : super([]) {
    loadNotes();
  }

  /// Loads all notes from the repository, sorting pinned notes first, then emits the sorted list.
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

  /// Adds a new note with given text, title, optional reminder, and id.
  ///
  /// Saves the note to the repository and reloads the notes.
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

  /// Deletes multiple notes from the repository.
  ///
  /// Cancels their notifications if any, then reloads the notes.
  Future<void> deleteNotes(List<Note> notesToDelete) async {
    for (final note in notesToDelete) {
      await repository.deleteNote(note);
      NotificationService().cancelNotification(note.id);
    }
    loadNotes();
  }

  /// Toggles the completion status of a given note.
  ///
  /// Updates the note in the repository and reloads the notes.
  Future<void> toggleCompletion(Note note) async {
    final updatedNote = note.toggleCompletion();

    await repository.updateNote(updatedNote);

    loadNotes();
  }

  /// Updates an existing note in the repository.
  ///
  /// Reloads notes and schedules a notification if the note has a reminder.
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

  /// Updates multiple notes in the repository.
  ///
  /// Schedules notifications for notes with reminders and reloads the notes.
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
