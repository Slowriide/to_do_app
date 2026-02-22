import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_state.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository(this._notes);

  List<Note> _notes;
  int updateNoteCalls = 0;
  int updateNotesCalls = 0;

  @override
  Future<void> addNote(Note newNote) async {
    _notes = [..._notes, newNote];
  }

  @override
  Future<void> deleteNote(Note note) async {
    _notes = _notes.where((n) => n.id != note.id).toList();
  }

  @override
  Future<List<Note>> getNotes() async => List<Note>.from(_notes);

  @override
  Future<void> updateNote(Note note) async {
    updateNoteCalls++;
    _notes = _notes.map((n) => n.id == note.id ? note : n).toList();
  }

  @override
  Future<void> updateNotes(List<Note> notes) async {
    updateNotesCalls++;
    final byId = {for (final n in notes) n.id: n};
    _notes = _notes.map((n) => byId[n.id] ?? n).toList();
  }
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('loads notes sorted with pinned first then by order', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'b', text: 'b', order: 2, isPinned: false),
      Note(id: 2, title: 'a', text: 'a', order: 3, isPinned: true),
      Note(id: 3, title: 'c', text: 'c', order: 1, isPinned: false),
      Note(id: 4, title: 'd', text: 'd', order: 0, isPinned: true),
    ]);
    final cubit = NoteCubit(repo);

    await _settle();

    expect(cubit.state.status, NoteStatus.success);
    expect(cubit.state.notes.map((n) => n.id).toList(), [4, 2, 3, 1]);
    await cubit.close();
  });

  test('reorderNotes persists in a single batch update', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', text: 'a', order: 0, isPinned: false),
      Note(id: 2, title: 'b', text: 'b', order: 1, isPinned: false),
      Note(id: 3, title: 'c', text: 'c', order: 2, isPinned: false),
    ]);
    final cubit = NoteCubit(repo);
    await _settle();

    await cubit.reorderNotes([
      cubit.state.notes[2],
      cubit.state.notes[0],
      cubit.state.notes[1],
    ]);

    expect(repo.updateNotesCalls, 1);
    expect(repo.updateNoteCalls, 0);
    expect(cubit.state.notes.map((n) => n.id).toList(), [3, 1, 2]);
    expect(cubit.state.notes.map((n) => n.order).toList(), [0, 1, 2]);
    await cubit.close();
  });

  test('reorderNoteByIds ignores movement across pin groups', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'p', text: 'p', order: 0, isPinned: true),
      Note(id: 2, title: 'u', text: 'u', order: 0, isPinned: false),
      Note(id: 3, title: 'u2', text: 'u2', order: 1, isPinned: false),
    ]);
    final cubit = NoteCubit(repo);
    await _settle();

    final before = cubit.state.notes.map((n) => n.id).toList();
    await cubit.reorderNoteByIds(1, 2);

    expect(repo.updateNotesCalls, 0);
    expect(cubit.state.notes.map((n) => n.id).toList(), before);
    await cubit.close();
  });

  test('archiveNotes archives and unpins notes', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', text: 'a', order: 0, isPinned: true),
      Note(id: 2, title: 'b', text: 'b', order: 1),
    ]);
    final cubit = NoteCubit(repo);
    await _settle();

    await cubit.archiveNotes([cubit.state.notes.first]);

    final archived = cubit.state.notes.firstWhere((n) => n.id == 1);
    expect(archived.isArchived, isTrue);
    expect(archived.isPinned, isFalse);
    await cubit.close();
  });

  test('archiveNotes reflows remaining active notes order', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', text: 'a', order: 0, isPinned: false),
      Note(id: 2, title: 'b', text: 'b', order: 1, isPinned: false),
      Note(id: 3, title: 'c', text: 'c', order: 2, isPinned: false),
    ]);
    final cubit = NoteCubit(repo);
    await _settle();

    final middle = cubit.state.notes.firstWhere((n) => n.id == 2);
    await cubit.archiveNotes([middle]);

    final active = cubit.state.notes.where((n) => !n.isArchived).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    expect(active.map((n) => n.id).toList(), [1, 3]);
    expect(active.map((n) => n.order).toList(), [0, 1]);
    await cubit.close();
  });

  test('restoreNotes restores archived notes', () async {
    final repo = FakeNoteRepository([
      Note(id: 1, title: 'a', text: 'a', order: 0, isArchived: true),
      Note(id: 2, title: 'b', text: 'b', order: 1),
    ]);
    final cubit = NoteCubit(repo);
    await _settle();

    final archived = cubit.state.notes.where((n) => n.isArchived).toList();
    await cubit.restoreNotes(archived);

    final restored = cubit.state.notes.firstWhere((n) => n.id == 1);
    expect(restored.isArchived, isFalse);
    await cubit.close();
  });

  test('addNote stores plain and rich text payload', () async {
    final repo = FakeNoteRepository([]);
    final cubit = NoteCubit(repo);
    await _settle();

    await cubit.addNote(
      'plain',
      'title',
      id: 99,
      richTextDeltaJson: '[{"insert":"plain\\n"}]',
    );

    final added = cubit.state.notes.firstWhere((n) => n.id == 99);
    expect(added.text, 'plain');
    expect(added.richTextDeltaJson, '[{"insert":"plain\\n"}]');
    await cubit.close();
  });
}
