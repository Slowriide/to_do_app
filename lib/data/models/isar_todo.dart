import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/todo.dart';

part 'isar_todo.g.dart';

/// A data model representing a Todo item in the Isar local database.
///
/// This class belongs to the data layer and is used for persistent storage.
/// It mirrors the structure of the domain-level [Todo] entity and includes:
///
/// - [id]: Auto-incremented unique identifier
/// - [title]: Title of the todo
/// - [isCompleted]: Completion status of the todo
/// - [isSubtask]: Whether this todo is a subtask of another
/// - [order]: Used to maintain subtask ordering
/// - [reminder]: Optional reminder date and time
/// - [isPinned]: Whether the todo is pinned
/// - [subtasks]: List of linked subtasks stored as [IsarLinks]
///
/// Includes conversion methods:
/// - [toDomain]: Converts this Isar model into the domain [Todo] entity
/// - [fromDomain]: Creates a [TodoIsar] from a domain [Todo], including its subtasks
@Collection()
class TodoIsar {
  Id id = Isar.autoIncrement;
  late String title;
  String? titleRichTextDeltaJson;
  late bool isCompleted;
  bool isSubtask = false;
  final subtasks = IsarLinks<TodoIsar>();
  late int order;
  DateTime? reminder;
  late bool isPinned;
  late bool isArchived;
  List<int> folderIds = [];

  Todo toDomain() {
    return Todo(
      id: id,
      title: title,
      titleRichTextDeltaJson: titleRichTextDeltaJson,
      isCompleted: isCompleted,
      subTasks: subtasks.map((subtask) => subtask.toDomain()).toList(),
      isSubtask: isSubtask,
      order: order,
      reminder: reminder,
      isPinned: isPinned,
      isArchived: isArchived,
      folderIds: folderIds,
    );
  }

  static TodoIsar fromDomain(Todo todo) {
    final todoIsar = TodoIsar()
      ..id = todo.id
      ..title = todo.title
      ..titleRichTextDeltaJson = todo.titleRichTextDeltaJson
      ..isSubtask = todo.isSubtask
      ..isCompleted = todo.isCompleted
      ..order = todo.order
      ..reminder = todo.reminder
      ..isPinned = todo.isPinned
      ..isArchived = todo.isArchived
      ..folderIds = todo.folderIds;
    for (var subtask in todo.subTasks) {
      todoIsar.subtasks.add(TodoIsar.fromDomain(subtask));
    }
    return todoIsar;
  }
}
