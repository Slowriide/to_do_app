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

    void handleReorder(int oldIndex, int newIndex) {
      final reordered = List<EditableSubtask>.from(subtasks);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      onReorder(reordered);
    }

    return Expanded(
      child: ReorderableListView.builder(
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
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    style: TextStyle(
                      color: theme.onTertiary,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: theme.tertiary,
                    ),
                    controller: item.controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: IconButton(
                        onPressed: onToggleComplete == null
                            ? null
                            : () => onToggleComplete!(index),
                        icon: Icon(
                          item.isCompleted
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: item.isCompleted
                              ? theme.onPrimary
                              : theme.tertiary,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed:
                            onDelete == null ? null : () => onDelete!(index),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
