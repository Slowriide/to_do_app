import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/todo.dart';

part 'isar_todo.g.dart';

@Collection()
class TodoIsar {
  Id id = Isar.autoIncrement;
  late String title;
  late bool isCompleted;
  bool isSubtask = false;
  final subtasks = IsarLinks<TodoIsar>();
  late int order;
  DateTime? reminder;
  late bool isPinned;

  Todo toDomain() {
    return Todo(
      id: id,
      title: title,
      isCompleted: isCompleted,
      subTasks: subtasks.map((subtask) => subtask.toDomain()).toList(),
      isSubtask: isSubtask,
      order: order,
      reminder: reminder,
      isPinned: isPinned,
    );
  }

  static TodoIsar fromDomain(Todo todo) {
    final todoIsar = TodoIsar()
      ..id = todo.id
      ..title = todo.title
      ..isSubtask = todo.isSubtask
      ..isCompleted = todo.isCompleted
      ..order = todo.order
      ..reminder = todo.reminder
      ..isPinned = todo.isPinned;
    for (var subtask in todo.subTasks) {
      todoIsar.subtasks.add(TodoIsar.fromDomain(subtask));
    }
    return todoIsar;
  }
}
