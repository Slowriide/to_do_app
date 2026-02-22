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
  String? titleRichTextDeltaJson;
  late String text;
  String? richTextDeltaJson;
  late bool isCompleted;
  DateTime? reminder;
  late bool isPinned;
  late bool isArchived;
  late int order;
  int? folderId;

//isar object to pure object
  Note toDomain() {
    return Note(
      id: id,
      title: title,
      titleRichTextDeltaJson: titleRichTextDeltaJson,
      text: text,
      richTextDeltaJson: richTextDeltaJson,
      isCompleted: isCompleted,
      reminder: reminder,
      isPinned: isPinned,
      isArchived: isArchived,
      order: order,
      folderId: folderId,
    );
  }

//pure object to isar object
  static NoteIsar fromDomain(Note note) {
    return NoteIsar()
      ..id = note.id
      ..titleRichTextDeltaJson = note.titleRichTextDeltaJson
      ..text = note.text
      ..richTextDeltaJson = note.richTextDeltaJson
      ..title = note.title
      ..isCompleted = note.isCompleted
      ..reminder = note.reminder
      ..isPinned = note.isPinned
      ..isArchived = note.isArchived
      ..order = note.order
      ..folderId = note.folderId;
  }
}
