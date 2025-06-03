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
  const TodoMasonryView({
    super.key,
    required this.todos,
    required this.selectedTodoIds,
    required this.isSelectionMode,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MasonryGridView.count(
          itemCount: todos.length,
          crossAxisCount: 2,
          itemBuilder: (context, index) {
            final todo = todos[index];
            final isSelected = selectedTodoIds.contains(todo.id);

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
                todo: todos[index],
                isSelected: isSelected,
              ),
            );
          },
        ),
      ],
    );
  }
}
