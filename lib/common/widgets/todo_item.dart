import 'package:flutter/material.dart';
import 'package:to_do_app/domain/models/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final bool isSelected;

  const TodoItem({
    super.key,
    required this.todo,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;

    final sortedSubtasks = [...todo.subTasks];
    sortedSubtasks.sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: !isSelected ? theme.primary : theme.onPrimary,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  todo.title,
                  style: textStyle.bodyMedium!.copyWith(fontSize: 21),
                  maxLines: 1,
                ),
              ),
              todo.isPinned
                  ? Icon(
                      Icons.push_pin_rounded,
                      color: const Color.fromARGB(213, 158, 158, 158),
                    )
                  : SizedBox(height: 0, width: 0),
            ],
          ),
          SizedBox(height: 10),
          if (todo.subTasks.isNotEmpty)
            ...sortedSubtasks.map((subtask) => Row(
                  children: [
                    Icon(
                      subtask.isCompleted
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: subtask.isCompleted
                          ? const Color.fromARGB(255, 77, 71, 165)
                          : Colors.grey,
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
                ))
        ],
      ),
    );
  }
}
