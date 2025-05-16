import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/note.dart';

part 'isar_note.g.dart';

@Collection()
class NoteIsar {
  Id id = Isar.autoIncrement;
  late String title;
  late String text;
  late bool isCompleted;
  DateTime? reminder;

//isar object to pure object
  Note toDomain() {
    return Note(
      id: id,
      title: title,
      text: text,
      isCompleted: isCompleted,
      reminder: reminder,
    );
  }

//pure object to isar object
  static NoteIsar fromDomain(Note note) {
    return NoteIsar()
      ..id = note.id
      ..text = note.text
      ..title = note.title
      ..isCompleted = note.isCompleted
      ..reminder = note.reminder;
  }
}
