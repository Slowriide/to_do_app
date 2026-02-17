import 'package:flutter/material.dart';
import 'package:to_do_app/domain/models/todo.dart';

/// A widget that displays a single todo item with its title and subtasks.
///
/// Used to represent a [Todo] in a list or grid. It shows the todo's title,
/// its subtasks (if any), and an optional pinned icon. Highlights the border
/// if the item is selected via [isSelected].
///
/// Subtasks are displayed in sorted order based on their order field.
class TodoItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  child: Text(
                    todo.title,
                    style: textStyle.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                todo.isPinned
                    ? Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: theme.tertiary,
                      )
                    : const SizedBox.shrink(),
                if (dragHandle != null) ...[
                  const SizedBox(width: 6),
                  dragHandle!,
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
