/// A domain model representing a task (todo) in the application.
///
/// The [Todo] class models a task which can optionally contain subtasks.
/// It includes properties such as title, completion status, ordering,
/// reminder, pin status, and whether the task itself is a subtask.
///
/// This class is immutable. To modify a task, use [copyWith] or [toggleCompletition].
class Todo {
  final int id;
  final String title;
  final bool isCompleted;
  final List<Todo> subTasks;
  final bool isSubtask;
  final int order;
  final DateTime? reminder;
  final bool isPinned;

  Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.subTasks,
    required this.isSubtask,
    required this.order,
    this.reminder,
    this.isPinned = false,
  });

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    List<Todo>? subTasks,
    bool? isSubtask,
    int? order,
    DateTime? reminder,
    bool? isPinned,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      isSubtask: isSubtask ?? this.isSubtask,
      order: order ?? this.order,
      reminder: reminder ?? this.reminder,
      isPinned: isPinned ?? this.isPinned,
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
    );
  }
}
