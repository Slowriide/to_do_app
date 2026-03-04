import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/core/notifications/pinned_note_widget_service.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/notes/note_state.dart';

/// Cubit that manages the list of notes.
///
/// Loads notes from the repository and emits updated lists.
///
/// Supports adding, deleting (single and multiple), updating, and toggling completion of notes.
///
/// Handles scheduling and canceling notifications based on note reminders.
class NoteCubit extends Cubit<NoteState> {
  final NoteRepository repository;
  final NoteSketchStorageService sketchStorage;
  final NotificationService notificationService;

  NoteCubit(
    this.repository, {
    NoteSketchStorageService? sketchStorage,
    NotificationService? notificationService,
  })  : sketchStorage = sketchStorage ?? createNoteSketchStorageService(),
        notificationService = notificationService ?? NotificationService(),
        super(const NoteState.loading()) {
    loadNotes();
  }

  /// Loads all notes from the repository, sorting pinned notes first, then emits the sorted list.
  Future<void> loadNotes() async {
    emit(NoteState.loading(state.notes));
    try {
      final notesList = await repository.getNotes();
      await _emitSortedNotes(notesList);
    } catch (e) {
      emit(NoteState.error('Failed to load notes', state.notes));
    }
  }

  /// Adds a new note with given text, title, optional reminder, and id.
  ///
  /// Saves the note to the repository and reloads the notes.
  Future<void> addNote(
    String text,
    String title, {
    DateTime? reminder,
    required int id,
    List<int>? folderIds,
    String? richTextDeltaJson,
    String? titleRichTextDeltaJson,
  }) async {
    final currentNotes = state.notes;
    final nextOrder = currentNotes.isEmpty
        ? 0
        : currentNotes.map((n) => n.order).reduce((a, b) => a > b ? a : b) + 1;
    final newNote = Note(
      id: id,
      title: title,
      titleRichTextDeltaJson: titleRichTextDeltaJson,
      text: text,
      richTextDeltaJson: richTextDeltaJson,
      reminder: reminder,
      order: nextOrder,
      folderIds: folderIds,
    );

    await repository.addNote(newNote);
    await _syncReminder(newNote);
    await _emitSortedNotes([...state.notes, newNote]);
  }

  /// Deletes multiple notes from the repository.
  ///
  /// Cancels their notifications if any, then reloads the notes.
  Future<void> deleteNotes(List<Note> notesToDelete) async {
    final sketchPaths = <String>{};
    for (final note in notesToDelete) {
      sketchPaths.addAll(
        sketchStorage.extractOwnedSketchPathsFromDelta(note.richTextDeltaJson),
      );
      await repository.deleteNote(note);
      await notificationService.cancelNoteReminder(note.id);
    }
    await sketchStorage.deleteFiles(sketchPaths);
    final idsToDelete = notesToDelete.map((note) => note.id).toSet();
    await _emitSortedNotes(
      state.notes.where((note) => !idsToDelete.contains(note.id)).toList(),
    );
  }

  /// Toggles the completion status of a given note.
  ///
  /// Updates the note in the repository and reloads the notes.
  Future<void> toggleCompletion(Note note) async {
    final updatedNote = note.toggleCompletion();

    await repository.updateNote(updatedNote);
    await _replaceLocalNote(updatedNote);
  }

  /// Updates an existing note in the repository.
  ///
  /// Reloads notes and schedules a notification if the note has a reminder.
  Future<void> updateNote(Note updateNote) async {
    await repository.updateNote(updateNote);
    await _syncReminder(updateNote);
    await _replaceLocalNote(updateNote);
  }

  /// Updates multiple notes in the repository.
  ///
  /// Schedules notifications for notes with reminders and reloads the notes.
  Future<void> updateNotes(List<Note> notes) async {
    await repository.updateNotes(notes);
    for (final note in notes) {
      await _syncReminder(note);
    }
    final byId = {for (final note in notes) note.id: note};
    final merged = state.notes.map((note) => byId[note.id] ?? note).toList();
    await _emitSortedNotes(merged);
  }

  /// Reorders notes based on the UI order and persists it.
  Future<void> reorderNotes(List<Note> orderedNotes) async {
    final reordered = List<Note>.generate(
        orderedNotes.length, (i) => orderedNotes[i].copyWith(order: i));
    await repository.updateNotes(reordered);
    await loadNotes();
  }

  /// Reorders notes by dragged and target ids.
  ///
  /// Reordering is constrained to notes within the same pin group so that
  /// pinned/unpinned sort behavior remains predictable.
  Future<void> reorderNoteByIds(int draggedId, int targetId) async {
    final notes = [...state.notes];
    final from = notes.indexWhere((n) => n.id == draggedId);
    final to = notes.indexWhere((n) => n.id == targetId);

    if (from < 0 || to < 0 || from == to) return;
    if (notes[from].isPinned != notes[to].isPinned) return;

    final moved = notes.removeAt(from);
    notes.insert(to, moved);

    final reordered = List<Note>.generate(
      notes.length,
      (i) => notes[i].copyWith(order: i),
    );
    await repository.updateNotes(reordered);
    await loadNotes();
  }

  Future<void> moveNotesToFolder(List<int> noteIds, int? folderId) async {
    final selected =
        state.notes.where((note) => noteIds.contains(note.id)).toList();
    for (final note in selected) {
      await repository.updateNote(
        note.copyWith(folderIds: folderId == null ? const [] : [folderId]),
      );
    }
    await loadNotes();
  }

  Future<void> moveNotesToFolders(List<int> noteIds, List<int> folderIds) async {
    final selected =
        state.notes.where((note) => noteIds.contains(note.id)).toList();
    final normalized = folderIds.toSet().toList();
    for (final note in selected) {
      await repository.updateNote(note.copyWith(folderIds: normalized));
    }
    await loadNotes();
  }

  Future<void> removeFolderFromNotes(List<int> noteIds, int folderId) async {
    final selected =
        state.notes.where((note) => noteIds.contains(note.id)).toList();
    for (final note in selected) {
      final updatedFolderIds =
          note.folderIds.where((id) => id != folderId).toList();
      await repository.updateNote(note.copyWith(folderIds: updatedFolderIds));
    }
    await loadNotes();
  }

  Future<void> archiveNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    final toArchiveIds = notes.map((note) => note.id).toSet();

    final archivedState = state.notes
        .map((note) => toArchiveIds.contains(note.id)
            ? note.copyWith(isArchived: true, isPinned: false)
            : note)
        .toList();

    final reflowed = _reflowActiveNotes(archivedState);
    await repository.updateNotes(reflowed);
    await loadNotes();
  }

  Future<void> restoreNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    final toRestoreIds = notes.map((note) => note.id).toSet();
    final restoredState = state.notes
        .map((note) => toRestoreIds.contains(note.id)
            ? note.copyWith(isArchived: false)
            : note)
        .toList();

    final reflowed = _reflowActiveNotes(restoredState);
    await repository.updateNotes(reflowed);
    await loadNotes();
  }

  List<Note> _reflowActiveNotes(List<Note> notes) {
    final active = notes.where((note) => !note.isArchived).toList()
      ..sort((a, b) {
        if (a.isPinned == b.isPinned) return a.order.compareTo(b.order);
        return a.isPinned ? -1 : 1;
      });

    final activeById = {
      for (var i = 0; i < active.length; i++)
        active[i].id: active[i].copyWith(order: i),
    };

    return notes.map((note) => activeById[note.id] ?? note).toList();
  }

  Future<void> _syncReminder(Note note) async {
    final reminder = note.reminder;
    if (reminder == null || !reminder.isAfter(DateTime.now())) {
      await notificationService.cancelNoteReminder(note.id);
      return;
    }
    await notificationService.scheduleNoteReminder(
      noteId: note.id,
      title: note.title,
      body: note.text,
      scheduledDate: reminder,
    );
  }

  Future<void> _replaceLocalNote(Note updatedNote) async {
    final notes = state.notes
        .map((note) => note.id == updatedNote.id ? updatedNote : note)
        .toList();
    await _emitSortedNotes(notes);
  }

  Future<void> _emitSortedNotes(List<Note> notes) async {
    final sortedNotes = [...notes]..sort((a, b) {
        if (a.isPinned == b.isPinned) return a.order.compareTo(b.order);
        return a.isPinned ? -1 : 1;
      });

    emit(NoteState.success(sortedNotes));
    try {
      await PinnedNoteWidgetService.refreshFromNotes(sortedNotes);
    } catch (e, st) {
      debugPrint('notes/widget-refresh failed: $e\n$st');
    }
  }
}
