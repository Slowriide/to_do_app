import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/note.dart';

class NoteListView extends StatefulWidget {
  final List<Note> notes;
  final Set<int> selectedNoteIds;
  final bool isSelectionMode;
  final Function(int id) onToggleSelect;
  final void Function(int draggedId, int targetId) onReorder;

  const NoteListView({
    super.key,
    required this.notes,
    required this.selectedNoteIds,
    required this.isSelectionMode,
    required this.onToggleSelect,
    required this.onReorder,
  });

  @override
  State<NoteListView> createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> {
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

  bool _canAccept(Note target, int draggedId) {
    if (widget.isSelectionMode) return false;
    if (draggedId == target.id) return false;

    Note? dragged;
    for (final note in widget.notes) {
      if (note.id == draggedId) {
        dragged = note;
        break;
      }
    }

    if (dragged == null) return false;
    return dragged.isPinned == target.isPinned;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return ListView.builder(
      key: const ValueKey('note_list_view'),
      itemCount: widget.notes.length,
      itemBuilder: (context, index) {
        final note = widget.notes[index];
        final isSelected = widget.selectedNoteIds.contains(note.id);
        final isDragging = _draggingId == note.id;

        return DragTarget<int>(
          key: ValueKey('note_list_target_${note.id}'),
          onWillAcceptWithDetails: (details) => _canAccept(note, details.data),
          onMove: (details) {
            if (!_canAccept(note, details.data) || _hoverTargetId == note.id) {
              return;
            }
            setState(() {
              _hoverTargetId = note.id;
            });
          },
          onLeave: (_) {
            if (_hoverTargetId != note.id) return;
            setState(() {
              _hoverTargetId = null;
            });
          },
          onAcceptWithDetails: (details) {
            widget.onReorder(details.data, note.id);
            _onDragFinished();
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isDragging ? 0.3 : 1,
              child: GestureDetector(
                onTap: () {
                  if (widget.isSelectionMode) {
                    widget.onToggleSelect(note.id);
                  } else {
                    context.push('/editNote', extra: note);
                  }
                },
                onLongPress: () => widget.onToggleSelect(note.id),
                child: NoteItem(
                  key: ValueKey('note_list_item_${note.id}'),
                  note: note,
                  isSelected: isSelected || isDropTarget,
                  dragHandle: widget.isSelectionMode
                      ? null
                      : Draggable<int>(
                          data: note.id,
                          maxSimultaneousDrags: 1,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          onDragStarted: () => _onDragStarted(note.id),
                          onDragCompleted: _onDragFinished,
                          onDraggableCanceled: (_, __) => _onDragFinished(),
                          onDragEnd: (_) => _onDragFinished(),
                          feedback: _NoteDragFeedback(note: note),
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
            );
          },
        );
      },
    );
  }
}

class _NoteDragFeedback extends StatelessWidget {
  final Note note;
  const _NoteDragFeedback({required this.note});

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
          width: 300,
          child: NoteItem(note: note, isSelected: true),
        ),
      ),
    );
  }
}
