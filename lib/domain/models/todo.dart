class Todo {
  final int id;
  final String title;
  final bool isCompleted;
  final List<Todo> subTasks;
  final bool isSubtask;

  Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.subTasks,
    required this.isSubtask,
  });

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    List<Todo>? subTasks,
    bool? isSubtask,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      isSubtask: isSubtask ?? this.isSubtask,
    );
  }

  Todo toggleCompletition() {
    return Todo(
      id: id,
      title: title,
      isCompleted: !isCompleted,
      subTasks: subTasks,
      isSubtask: isSubtask,
    );
  }
}
