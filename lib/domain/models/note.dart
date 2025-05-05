class Note {
  final int id;
  final String title;
  final String text;
  final bool isCompleted;

  Note({
    required this.id,
    required this.title,
    required this.text,
    this.isCompleted = false,
  });

  Note toggleCompletion() {
    return Note(
      id: id,
      title: title,
      text: text,
      isCompleted: !isCompleted,
    );
  }

  Note copyWith({
    String? title,
    String? text,
    bool? isCompleted,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
