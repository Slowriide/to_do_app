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
class MasonryView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      itemCount: notes.length,
      crossAxisCount: 2,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = selectedNoteIds.contains(note.id);
        final theme = Theme.of(context).colorScheme;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            if (isSelectionMode) return false;
            final draggedId = details.data;
            if (draggedId == note.id) return false;
            Note? dragged;
            for (final n in notes) {
              if (n.id == draggedId) {
                dragged = n;
                break;
              }
            }
            if (dragged == null) return false;
            return dragged.isPinned == note.isPinned;
          },
          onAcceptWithDetails: (details) {
            onReorder(details.data, note.id);
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (isSelectionMode) {
                  onToggleSelect(note.id);
                } else {
                  context.push('/editNote', extra: note);
                }
              },
              onLongPress: () => onToggleSelect(note.id),
              child: NoteItem(
                note: note,
                isSelected: isSelected || isDropTarget,
                dragHandle: isSelectionMode
                    ? null
                    : Draggable<int>(
                        data: note.id,
                        maxSimultaneousDrags: 1,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 180,
                            child: NoteItem(note: note, isSelected: true),
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
