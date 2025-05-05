import 'package:isar/isar.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';

class IsarNoteRepositoryImpl implements NoteRepository {
  final Isar db;
  IsarNoteRepositoryImpl(this.db);

  @override
  Future<void> addNote(Note newNote) async {
    //convert note in isartodo
    final noteIsar = NoteIsar.fromDomain(newNote);

    //store in db
    return db.writeTxn(() => db.noteIsars.put(noteIsar));
  }

  @override
  Future<void> deleteNote(Note note) async {
    return db.writeTxn(() => db.noteIsars.delete(note.id));
  }

  @override
  Future<List<Note>> getNotes() async {
    //fetch from db
    final notes = await db.noteIsars.where().findAll();

    //return as a list of todos and give to domain layer
    return notes.map((noteIsar) => noteIsar.toDomain()).toList();
  }

  @override
  Future<void> updateNote(Note note) {
    //convert note in isartodo
    final noteIsar = NoteIsar.fromDomain(note);

    //store in db
    return db.writeTxn(() => db.noteIsars.put(noteIsar));
  }
}
