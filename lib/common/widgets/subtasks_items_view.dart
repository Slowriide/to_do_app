import 'package:flutter/material.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';

class SubtaskItemsView extends StatelessWidget {
  final List<EditableSubtask> subtasks;
  final void Function(int index)? onToggleComplete;
  final void Function(int index)? onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
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
      child: ReorderableListView.builder(
        itemCount: subtasks.length,
        onReorder: onReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final editable = subtasks[index];
          return Dismissible(
            key: ValueKey(editable),
            background: Container(color: Colors.red),
            onDismissed: (_) => onDelete!(index),
            child: ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle_outlined),
                    Expanded(
                      child: TextFormField(
                        style: TextStyle(
                          color:
                              editable.isCompleted ? Colors.grey : Colors.white,
                          decoration: editable.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey,
                        ),
                        controller: editable.controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: IconButton(
                            onPressed: () => onToggleComplete!(index),
                            icon: Icon(
                              editable.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: editable.isCompleted
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
