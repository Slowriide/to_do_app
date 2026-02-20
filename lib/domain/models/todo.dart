/// A domain model representing a task (todo) in the application.
///
/// The [Todo] class models a task which can optionally contain subtasks.
/// It includes properties such as title, completion status, ordering,
/// reminder, pin status, and whether the task itself is a subtask.
///
/// This class is immutable. To modify a task, use [copyWith] or [toggleCompletition].
class Todo {
  static const Object _unset = Object();

  final int id;
  final String title;
  final bool isCompleted;
  final List<Todo> subTasks;
  final bool isSubtask;
  final int order;
  final DateTime? reminder;
  final bool isPinned;
  final bool isArchived;
  final int? folderId;

  Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.subTasks,
    required this.isSubtask,
    required this.order,
    this.reminder,
    this.isPinned = false,
    this.isArchived = false,
    this.folderId,
  });

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    List<Todo>? subTasks,
    bool? isSubtask,
    int? order,
    Object? reminder = _unset,
    bool? isPinned,
    bool? isArchived,
    Object? folderId = _unset,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      isSubtask: isSubtask ?? this.isSubtask,
      order: order ?? this.order,
      reminder:
          identical(reminder, _unset) ? this.reminder : reminder as DateTime?,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      folderId:
          identical(folderId, _unset) ? this.folderId : folderId as int?,
    );
  }

  Todo toggleCompletition() {
    return Todo(
      id: id,
      title: title,
      isCompleted: !isCompleted,
      subTasks: subTasks,
      isSubtask: isSubtask,
      order: order,
      reminder: reminder,
      isPinned: isPinned,
      isArchived: isArchived,
      folderId: folderId,
    );
  }
}
