import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/note.dart';

/// Displays a staggered grid view of notes.
///
/// Supports multi-selection mode: tapping a note either toggles selection
/// (if in selection mode) or navigates to the edit page (otherwise).
/// Long pressing a note also toggles its selection.
///
/// The grid uses 2 columns and displays notes in a masonry (Pinterest-like) style.
///
/// Parameters:
/// - [notes]: the list of ToDos to display.
/// - [selectedNoteIds]: the set of currently selected ToDo IDs.
/// - [isSelectionMode]: whether the view is in selection mode.
/// - [onToggleSelect]: callback for toggling the selection of a ToDo.
class MasonryView extends StatefulWidget {
  final List<Note> notes;
  final Set<int> selectedNoteIds;
  final bool isSelectionMode;
  final Function(int id) onToggleSelect;
  final void Function(int draggedId, int targetId) onReorder;
  const MasonryView({
    super.key,
    required this.notes,
    required this.selectedNoteIds,
    required this.isSelectionMode,
    required this.onToggleSelect,
    required this.onReorder,
  });

  @override
  State<MasonryView> createState() => _MasonryViewState();
}

class _MasonryViewState extends State<MasonryView> {
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

  Offset _shiftForIndex(int index) {
    if (_draggingId == null || _hoverTargetId == null) return Offset.zero;

    final draggedIndex = widget.notes.indexWhere((n) => n.id == _draggingId);
    final targetIndex = widget.notes.indexWhere((n) => n.id == _hoverTargetId);
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
      itemCount: widget.notes.length,
      crossAxisCount: 2,
      itemBuilder: (context, index) {
        final note = widget.notes[index];
        final isSelected = widget.selectedNoteIds.contains(note.id);
        final theme = Theme.of(context).colorScheme;
        final isDragging = _draggingId == note.id;
        final slideOffset = _shiftForIndex(index);

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            return _canAccept(note, details.data);
          },
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
            return GestureDetector(
              onTap: () {
                if (widget.isSelectionMode) {
                  widget.onToggleSelect(note.id);
                } else {
                  context.push('/editNote', extra: note);
                }
              },
              onLongPress: () => widget.onToggleSelect(note.id),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: slideOffset,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  scale: isDropTarget ? 1.02 : 1,
                  child: AnimatedOpacity(
                    key: ValueKey('note_${note.id}'),
                    duration: const Duration(milliseconds: 180),
                    opacity: isDragging ? 0.3 : 1,
                    child: NoteItem(
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
          width: 210,
          child: NoteItem(note: note, isSelected: true),
        ),
      ),
    );
  }
}
