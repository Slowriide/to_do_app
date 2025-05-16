class Todo {
  final int id;
  final String title;
  final bool isCompleted;
  final List<Todo> subTasks;
  final bool isSubtask;
  final int order;
  final DateTime? reminder;

  Todo(
      {required this.id,
      required this.title,
      required this.isCompleted,
      required this.subTasks,
      required this.isSubtask,
      required this.order,
      this.reminder});

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    List<Todo>? subTasks,
    bool? isSubtask,
    int? order,
    DateTime? reminder,
  }) {
    return Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        subTasks: subTasks ?? this.subTasks,
        isSubtask: isSubtask ?? this.isSubtask,
        order: order ?? this.order,
        reminder: reminder ?? this.reminder);
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
    );
  }
}
