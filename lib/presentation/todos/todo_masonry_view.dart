import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/todo_item.dart';
import 'package:to_do_app/domain/models/todo.dart';

/// Displays a staggered grid view of todos.
///
/// Supports multi-selection mode: tapping a note either toggles selection
/// (if in selection mode) or navigates to the edit page (otherwise).
/// Long pressing a note also toggles its selection.
///
/// The grid uses 2 columns and displays notes in a masonry (Pinterest-like) style.
///
/// Parameters:
/// - [todos]: the list of ToDos to display.
/// - [selectedTodoIds]: the set of currently selected ToDo IDs.
/// - [isSelectionMode]: whether the view is in selection mode.
/// - [onToggleSelect]: callback for toggling the selection of a ToDo.
class TodoMasonryView extends StatelessWidget {
  final List<Todo> todos;
  final Set<int> selectedTodoIds;
  final bool isSelectionMode;
  final Function(int id) onToggleSelect;
  final void Function(int draggedId, int targetId) onReorder;
  const TodoMasonryView({
    super.key,
    required this.todos,
    required this.selectedTodoIds,
    required this.isSelectionMode,
    required this.onToggleSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final isSelected = selectedTodoIds.contains(todo.id);
        final theme = Theme.of(context).colorScheme;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            if (isSelectionMode) return false;
            final draggedId = details.data;
            if (draggedId == todo.id) return false;
            Todo? dragged;
            for (final t in todos) {
              if (t.id == draggedId) {
                dragged = t;
                break;
              }
            }
            if (dragged == null) return false;
            return dragged.isPinned == todo.isPinned;
          },
          onAcceptWithDetails: (details) {
            onReorder(details.data, todo.id);
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (isSelectionMode) {
                  onToggleSelect(todo.id);
                } else {
                  context.push('/edittodo', extra: todo);
                }
              },
              onLongPress: () => onToggleSelect(todo.id),
              child: TodoItem(
                todo: todo,
                isSelected: isSelected || isDropTarget,
                dragHandle: isSelectionMode
                    ? null
                    : Draggable<int>(
                        data: todo.id,
                        maxSimultaneousDrags: 1,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 180,
                            child: TodoItem(todo: todo, isSelected: true),
                          ),
                        ),
                        childWhenDragging: Icon(
                          Icons.drag_indicator_rounded,
                          color: theme.tertiary.withValues(alpha: 0.5),
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: theme.tertiary,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
