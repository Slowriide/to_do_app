import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/domain/models/todo.dart';

/// A widget that displays a single todo item with its title and subtasks.
///
/// Used to represent a [Todo] in a list or grid. It shows the todo's title,
/// its subtasks (if any), and an optional pinned icon. Highlights the border
/// if the item is selected via [isSelected].
///
/// Subtasks are displayed in sorted order based on their order field.
class TodoItem extends StatefulWidget {
  final Todo todo;
  final bool isSelected;
  final Widget? dragHandle;

  const TodoItem({
    super.key,
    required this.todo,
    required this.isSelected,
    this.dragHandle,
  });

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  static const _titlePreviewMaxHeight = 50.0;
  static const _previewConfig = quill.QuillEditorConfig(
    scrollable: false,
    expands: false,
    showCursor: false,
    enableInteractiveSelection: false,
    padding: EdgeInsets.zero,
  );

  late final quill.QuillController _titlePreviewController;
  late final FocusNode _titlePreviewFocusNode;
  late final ScrollController _titlePreviewScrollController;

  @override
  void initState() {
    super.initState();
    _titlePreviewController = quill.QuillController(
      document: NoteRichTextCodec.documentFromRaw(
        rawDelta: widget.todo.titleRichTextDeltaJson,
        fallbackPlainText: widget.todo.title,
      ),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _titlePreviewFocusNode =
        FocusNode(skipTraversal: true, canRequestFocus: false);
    _titlePreviewScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant TodoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final richChanged = oldWidget.todo.titleRichTextDeltaJson !=
        widget.todo.titleRichTextDeltaJson;
    final titleChanged = oldWidget.todo.title != widget.todo.title;
    if (richChanged || titleChanged) {
      _titlePreviewController.document = NoteRichTextCodec.documentFromRaw(
        rawDelta: widget.todo.titleRichTextDeltaJson,
        fallbackPlainText: widget.todo.title,
      );
    }
  }

  @override
  void dispose() {
    _titlePreviewController.dispose();
    _titlePreviewFocusNode.dispose();
    _titlePreviewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final isSelected = widget.isSelected;
    final dragHandle = widget.dragHandle;
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    final cardColor = _todoTint(todo.id, theme);

    final sortedSubtasks = [...todo.subTasks];
    sortedSubtasks.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.75)
              : theme.tertiary.withValues(alpha: 0.28),
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: textStyle.bodyLarge ?? const TextStyle(fontSize: 16),
                    child: ClipRect(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _titlePreviewMaxHeight,
                        ),
                        child: IgnorePointer(
                          child: quill.QuillEditor(
                            controller: _titlePreviewController,
                            focusNode: _titlePreviewFocusNode,
                            scrollController: _titlePreviewScrollController,
                            config: _previewConfig,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                todo.isPinned
                    ? Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: theme.tertiary,
                      )
                    : const SizedBox.shrink(),
                if (dragHandle case final handle?) ...[
                  const SizedBox(width: 6),
                  handle,
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (todo.subTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: sortedSubtasks
                    .take(5)
                    .map(
                      (subtask) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              subtask.isCompleted
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: subtask.isCompleted
                                  ? theme.primary
                                  : theme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subtask.title,
                                style: textStyle.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
        ],
      ),
    );
  }

  Color _todoTint(int id, ColorScheme theme) {
    const lightTints = <Color>[
      Color(0xFFFFEFC0),
      Color(0xFFDCF4DF),
      Color(0xFFD9EDFF),
      Color(0xFFFFE6D6),
      Color(0xFFECE2FF),
      Color(0xFFFDE0EC),
    ];
    const darkTints = <Color>[
      Color(0xFF384528),
      Color(0xFF24453B),
      Color(0xFF27435D),
      Color(0xFF533722),
      Color(0xFF3D3259),
      Color(0xFF522A3B),
    ];
    final isDark = theme.brightness == Brightness.dark;
    final tints = isDark ? darkTints : lightTints;
    return Color.alphaBlend(
      tints[id.abs() % tints.length].withValues(alpha: isDark ? 0.42 : 0.28),
      theme.surface,
    );
  }
}
