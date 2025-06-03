import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
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
    return Expanded(
      child: ImplicitlyAnimatedReorderableList<EditableSubtask>(
        items: subtasks,
        areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
        onReorderFinished: (item, from, to, newItems) {
          onReorder(newItems);
        },
        itemBuilder: (context, animation, item, index) {
          final theme = Theme.of(context).colorScheme;
          return Reorderable(
            key: ValueKey(item.id),
            child: SizeFadeTransition(
              animation: animation,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Handle(child: Icon(Icons.drag_handle_outlined)),
                    Expanded(
                      child: TextFormField(
                        style: TextStyle(
                          color: item.isCompleted
                              ? theme.tertiary
                              : theme.onTertiary,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: theme.tertiary,
                        ),
                        controller: item.controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: IconButton(
                            onPressed: () => onToggleComplete!(index),
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
                            onPressed: () => onDelete!(index),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
