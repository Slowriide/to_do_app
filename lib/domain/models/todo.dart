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
  final String? titleRichTextDeltaJson;
  final bool isCompleted;
  final List<Todo> subTasks;
  final bool isSubtask;
  final int order;
  final DateTime? reminder;
  final bool isPinned;
  final bool isArchived;
  final List<int> folderIds;

  Todo({
    required this.id,
    required this.title,
    this.titleRichTextDeltaJson,
    required this.isCompleted,
    required this.subTasks,
    required this.isSubtask,
    required this.order,
    this.reminder,
    this.isPinned = false,
    this.isArchived = false,
    List<int>? folderIds,
  }) : folderIds = List.unmodifiable(folderIds ?? const []);

  Todo copyWith({
    int? id,
    String? title,
    Object? titleRichTextDeltaJson = _unset,
    bool? isCompleted,
    List<Todo>? subTasks,
    bool? isSubtask,
    int? order,
    Object? reminder = _unset,
    bool? isPinned,
    bool? isArchived,
    Object? folderIds = _unset,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      titleRichTextDeltaJson: identical(titleRichTextDeltaJson, _unset)
          ? this.titleRichTextDeltaJson
          : titleRichTextDeltaJson as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      isSubtask: isSubtask ?? this.isSubtask,
      order: order ?? this.order,
      reminder:
          identical(reminder, _unset) ? this.reminder : reminder as DateTime?,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      folderIds: identical(folderIds, _unset)
          ? this.folderIds
          : List<int>.unmodifiable((folderIds as List<int>?) ?? const []),
    );
  }

  Todo toggleCompletition() {
    return Todo(
      id: id,
      title: title,
      titleRichTextDeltaJson: titleRichTextDeltaJson,
      isCompleted: !isCompleted,
      subTasks: subTasks,
      isSubtask: isSubtask,
      order: order,
      reminder: reminder,
      isPinned: isPinned,
      isArchived: isArchived,
      folderIds: folderIds,
    );
  }
}
