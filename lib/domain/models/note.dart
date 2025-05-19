class Note {
  final int id;
  final String title;
  final String text;
  final bool isCompleted;
  final DateTime? reminder;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.text,
    this.isCompleted = false,
    this.reminder,
    this.isPinned = false,
  });

  Note toggleCompletion() {
    return Note(
      id: id,
      title: title,
      text: text,
      isCompleted: !isCompleted,
      reminder: reminder,
      isPinned: isPinned,
    );
  }

  Note copyWith({
    String? title,
    String? text,
    bool? isCompleted,
    DateTime? reminder,
    bool? isPinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      reminder: reminder ?? this.reminder,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
