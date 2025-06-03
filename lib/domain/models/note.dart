/// A domain model representing a note item in the application.
///
/// The [Note] class encapsulates the core data and behaviors of a note,
/// including its title, content text, completion status, optional reminder date,
/// and whether the note is pinned.
///
/// This class is immutable. To modify a note, use [copyWith] or [toggleCompletion].
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
