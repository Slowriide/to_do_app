import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';

class SubtaskItemsView extends StatelessWidget {
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
                          color: item.isCompleted ? Colors.grey : Colors.white,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey,
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
                                  ? Color.fromARGB(255, 64, 79, 165)
                                  : Colors.grey,
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
