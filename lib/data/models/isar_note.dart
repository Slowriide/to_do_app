import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/note.dart';

part 'isar_note.g.dart';

/// A database model representing a note in the Isar local database.
///
/// This model is used exclusively for persistence purposes and mirrors
/// the structure of the domain-level [Note] entity. It includes fields such as:
/// - [title]: The note's title.
/// - [text]: The note content.
/// - [isCompleted]: Whether the note is completed.
/// - [reminder]: An optional reminder date.
/// - [isPinned]: Whether the note is pinned.
///
/// Conversion methods are provided to map between [NoteIsar] and the
/// domain model [Note] for use across the application layers.
@Collection()
class NoteIsar {
  Id id = Isar.autoIncrement;
  late String title;
  late String text;
  late bool isCompleted;
  DateTime? reminder;
  late bool isPinned;

//isar object to pure object
  Note toDomain() {
    return Note(
      id: id,
      title: title,
      text: text,
      isCompleted: isCompleted,
      reminder: reminder,
      isPinned: isPinned,
    );
  }

//pure object to isar object
  static NoteIsar fromDomain(Note note) {
    return NoteIsar()
      ..id = note.id
      ..text = note.text
      ..title = note.title
      ..isCompleted = note.isCompleted
      ..reminder = note.reminder
      ..isPinned = note.isPinned;
  }
}
