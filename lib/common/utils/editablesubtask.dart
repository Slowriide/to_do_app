import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Model representing an editable subtask in the UI.
///
/// Each instance holds a [TextEditingController] to manage the text input,
/// a unique identifier [id], a completion status [isCompleted],
/// and an [order] indicating its position in the list.
///
/// This class only manages the UI state and local data for each editable subtask.
class EditableSubtask {
  final int id;
  final quill.QuillController controller;
  bool isCompleted;
  int order;

  EditableSubtask({
    required this.id,
    required this.controller,
    this.isCompleted = false,
    this.order = 0,
  });
}
