import 'package:flutter/material.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';

/// Displays a list of editable subtasks with drag-and-drop support.
///
/// This widget allows users to reorder subtasks, toggle completion, and delete them.
/// Animations and reordering behavior are powered by the [ImplicitlyAnimatedReorderableList] package.
class SubtaskItemsView extends StatelessWidget {
  /// Creates a view to display and manage a list of subtasks.
  ///
  /// [subtasks] is the list of subtasks to display.
  /// [onToggleComplete] is called when a subtask is toggled as complete/incomplete.
  /// [onDelete] is called when a subtask is removed.
  /// [onReorder] is called with the new order when the list is reordered.
  final List<EditableSubtask> subtasks;
  final void Function(int index)? onToggleComplete;
  final void Function(int index)? onDelete;
  final void Function(List<EditableSubtask> newOrder) onReorder;
  const SubtaskItemsView({
    super.key,
    required this.subtasks,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleReorder(int oldIndex, int newIndex) {
      final reordered = List<EditableSubtask>.from(subtasks);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      onReorder(reordered);
    }

    return ReorderableListView.builder(
      itemCount: subtasks.length,
      buildDefaultDragHandles: false,
      onReorder: handleReorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final item = subtasks[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: theme.onInverseSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.tertiary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.drag_indicator_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: item.isCompleted ? 0.72 : 1,
                    child: TextFormField(
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.onSurface,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: theme.tertiary,
                      ),
                      controller: item.controller,
                      decoration: InputDecoration(
                        hintText: 'Subtask',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        prefixIcon: IconButton(
                          onPressed: onToggleComplete == null
                              ? null
                              : () => onToggleComplete!(index),
                          tooltip: item.isCompleted
                              ? 'Mark as pending'
                              : 'Mark as complete',
                          icon: Icon(
                            item.isCompleted
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: item.isCompleted
                                ? theme.onPrimary
                                : theme.tertiary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Delete subtask',
                          onPressed:
                              onDelete == null ? null : () => onDelete!(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
