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
  static const _subtaskPreviewMaxHeight = 30.0;
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
  final Map<int, _SubtaskPreviewControllers> _subtaskControllers = {};

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
    _syncSubtaskControllers(widget.todo.subTasks);
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
    _syncSubtaskControllers(widget.todo.subTasks);
  }

  @override
  void dispose() {
    _titlePreviewController.dispose();
    _titlePreviewFocusNode.dispose();
    _titlePreviewScrollController.dispose();
    for (final bundle in _subtaskControllers.values) {
      bundle.dispose();
    }
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
    final createdAtLabel = _formatCreatedAt(context, todo.id);

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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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
                              child: DefaultTextStyle.merge(
                                style: textStyle.bodyMedium ??
                                    const TextStyle(fontSize: 14),
                                child: ClipRect(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: _subtaskPreviewMaxHeight,
                                    ),
                                    child: IgnorePointer(
                                      child: quill.QuillEditor(
                                        controller: _subtaskControllers[
                                                subtask.id]!
                                            .controller,
                                        focusNode: _subtaskControllers[
                                                subtask.id]!
                                            .focusNode,
                                        scrollController:
                                            _subtaskControllers[subtask.id]!
                                                .scrollController,
                                        config: _previewConfig,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (createdAtLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                createdAtLabel,
                style: textStyle.labelSmall?.copyWith(
                  color: theme.onSurfaceVariant.withValues(alpha: 0.78),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _formatCreatedAt(BuildContext context, int id) {
    final createdAt = _createdAtFromId(id);
    if (createdAt == null) return null;

    final localizations = MaterialLocalizations.of(context);
    final use24h =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final date = localizations.formatShortDate(createdAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(createdAt),
      alwaysUse24HourFormat: use24h,
    );
    return '$date $time';
  }

  DateTime? _createdAtFromId(int id) {
    if (id <= 0) return null;
    try {
      final date = DateTime.fromMicrosecondsSinceEpoch(id);
      if (date.year < 2000 || date.year > 2100) return null;
      return date;
    } catch (_) {
      return null;
    }
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

  void _syncSubtaskControllers(List<Todo> subtasks) {
    final currentIds = subtasks.map((subtask) => subtask.id).toSet();

    final removedIds = _subtaskControllers.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in removedIds) {
      _subtaskControllers.remove(id)?.dispose();
    }

    for (final subtask in subtasks) {
      final existing = _subtaskControllers[subtask.id];
      if (existing == null) {
        _subtaskControllers[subtask.id] = _SubtaskPreviewControllers(
          document: NoteRichTextCodec.documentFromRaw(
            rawDelta: subtask.titleRichTextDeltaJson,
            fallbackPlainText: subtask.title,
          ),
        );
        continue;
      }

      existing.controller.document = NoteRichTextCodec.documentFromRaw(
        rawDelta: subtask.titleRichTextDeltaJson,
        fallbackPlainText: subtask.title,
      );
    }
  }
}

class _SubtaskPreviewControllers {
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  _SubtaskPreviewControllers({
    required quill.Document document,
  })  : controller = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        ),
        focusNode = FocusNode(skipTraversal: true, canRequestFocus: false),
        scrollController = ScrollController();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }
}
