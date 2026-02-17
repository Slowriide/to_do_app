import 'package:flutter/material.dart';
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
  final void Function(List<Todo> reorderedTodos) onReorder;
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
    return ReorderableListView.builder(
      itemCount: todos.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        final reordered = List<Todo>.from(todos);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        onReorder(reordered);
      },
      itemBuilder: (context, index) {
        final todo = todos[index];
        final isSelected = selectedTodoIds.contains(todo.id);

        return Row(
          key: ValueKey(todo.id),
          children: [
            if (!isSelectionMode)
              ReorderableDragStartListener(
                index: index,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.drag_indicator_rounded),
                ),
              ),
            Expanded(
              child: GestureDetector(
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
                  isSelected: isSelected,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
