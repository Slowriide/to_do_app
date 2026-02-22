/// A domain model representing a note item in the application.
///
/// The [Note] class encapsulates the core data and behaviors of a note,
/// including its title, content text, completion status, optional reminder date,
/// and whether the note is pinned.
///
/// This class is immutable. To modify a note, use [copyWith] or [toggleCompletion].
class Note {
  static const Object _unset = Object();

  final int id;
  final String title;
  final String text;
  final String? richTextDeltaJson;
  final bool isCompleted;
  final DateTime? reminder;
  final bool isPinned;
  final bool isArchived;
  final int order;
  final int? folderId;

  Note({
    required this.id,
    required this.title,
    required this.text,
    this.richTextDeltaJson,
    this.isCompleted = false,
    this.reminder,
    this.isPinned = false,
    this.isArchived = false,
    this.order = 0,
    this.folderId,
  });

  Note toggleCompletion() {
    return Note(
      id: id,
      title: title,
      text: text,
      richTextDeltaJson: richTextDeltaJson,
      isCompleted: !isCompleted,
      reminder: reminder,
      isPinned: isPinned,
      isArchived: isArchived,
      order: order,
      folderId: folderId,
    );
  }

  Note copyWith({
    String? title,
    String? text,
    Object? richTextDeltaJson = _unset,
    bool? isCompleted,
    Object? reminder = _unset,
    bool? isPinned,
    bool? isArchived,
    int? order,
    Object? folderId = _unset,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      richTextDeltaJson: identical(richTextDeltaJson, _unset)
          ? this.richTextDeltaJson
          : richTextDeltaJson as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      reminder:
          identical(reminder, _unset) ? this.reminder : reminder as DateTime?,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      order: order ?? this.order,
      folderId: identical(folderId, _unset) ? this.folderId : folderId as int?,
    );
  }
}
