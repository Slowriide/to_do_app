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
class TodoMasonryView extends StatefulWidget {
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
  State<TodoMasonryView> createState() => _TodoMasonryViewState();
}

class _TodoMasonryViewState extends State<TodoMasonryView> {
  int? _draggingId;
  int? _hoverTargetId;

  void _onDragStarted(int id) {
    setState(() {
      _draggingId = id;
    });
  }

  void _onDragFinished() {
    if (!mounted) return;
    setState(() {
      _draggingId = null;
      _hoverTargetId = null;
    });
  }

  bool _canAccept(Todo target, int draggedId) {
    if (widget.isSelectionMode) return false;
    if (draggedId == target.id) return false;

    Todo? dragged;
    for (final todo in widget.todos) {
      if (todo.id == draggedId) {
        dragged = todo;
        break;
      }
    }

    if (dragged == null) return false;
    return dragged.isPinned == target.isPinned;
  }

  Offset _shiftForIndex(int index) {
    if (_draggingId == null || _hoverTargetId == null) return Offset.zero;

    final draggedIndex = widget.todos.indexWhere((t) => t.id == _draggingId);
    final targetIndex = widget.todos.indexWhere((t) => t.id == _hoverTargetId);
    if (draggedIndex < 0 || targetIndex < 0 || draggedIndex == targetIndex) {
      return Offset.zero;
    }

    if (draggedIndex < targetIndex &&
        index > draggedIndex &&
        index <= targetIndex) {
      return const Offset(0, -0.07);
    }

    if (draggedIndex > targetIndex &&
        index >= targetIndex &&
        index < draggedIndex) {
      return const Offset(0, 0.07);
    }

    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: widget.todos.length,
      itemBuilder: (context, index) {
        final todo = widget.todos[index];
        final isSelected = widget.selectedTodoIds.contains(todo.id);
        final theme = Theme.of(context).colorScheme;
        final isDragging = _draggingId == todo.id;
        final slideOffset = _shiftForIndex(index);

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            return _canAccept(todo, details.data);
          },
          onMove: (details) {
            if (!_canAccept(todo, details.data) || _hoverTargetId == todo.id) {
              return;
            }
            setState(() {
              _hoverTargetId = todo.id;
            });
          },
          onLeave: (_) {
            if (_hoverTargetId != todo.id) return;
            setState(() {
              _hoverTargetId = null;
            });
          },
          onAcceptWithDetails: (details) {
            widget.onReorder(details.data, todo.id);
            _onDragFinished();
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (widget.isSelectionMode) {
                  widget.onToggleSelect(todo.id);
                } else {
                  context.push('/edittodo', extra: todo);
                }
              },
              onLongPress: () => widget.onToggleSelect(todo.id),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: slideOffset,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  scale: isDropTarget ? 1.02 : 1,
                  child: AnimatedOpacity(
                    key: ValueKey('todo_${todo.id}'),
                    duration: const Duration(milliseconds: 180),
                    opacity: isDragging ? 0.3 : 1,
                    child: TodoItem(
                      todo: todo,
                      isSelected: isSelected || isDropTarget,
                      dragHandle: widget.isSelectionMode
                          ? null
                          : Draggable<int>(
                              data: todo.id,
                              maxSimultaneousDrags: 1,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              onDragStarted: () => _onDragStarted(todo.id),
                              onDragCompleted: _onDragFinished,
                              onDraggableCanceled: (_, __) => _onDragFinished(),
                              onDragEnd: (_) => _onDragFinished(),
                              feedback: _TodoDragFeedback(todo: todo),
                              childWhenDragging: Icon(
                                Icons.drag_indicator_rounded,
                                color: theme.tertiary.withValues(alpha: 0.45),
                              ),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: theme.tertiary,
                              ),
                            ),
                    ),
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

class _TodoDragFeedback extends StatelessWidget {
  final Todo todo;
  const _TodoDragFeedback({required this.todo});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        elevation: 14,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 210,
          child: TodoItem(todo: todo, isSelected: true),
        ),
      ),
    );
  }
}
