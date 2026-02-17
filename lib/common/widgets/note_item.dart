import 'package:flutter/material.dart';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/domain/models/note.dart';

/// A widget that displays a single note item with its title and text.
///
/// Used to represent a note inside a list or grid. It shows the note's title,
/// text, and an optional pinned icon. If [isSelected] is true, the note's border
/// is highlighted.
///
/// This widget does not handle interaction logic; it is purely presentational.

class NoteItem extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final Widget? dragHandle;

  const NoteItem({
    super.key,
    required this.note,
    required this.isSelected,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    final cardColor = _noteTint(note.id, theme);

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
            color: Colors.black.withValues(alpha: 0.06),
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
                    note.title,
                    style: textStyle.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                note.isPinned
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Text(
              note.text,
              style: textStyle.bodyMedium,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _noteTint(int id, ColorScheme theme) {
    const lightTints = <Color>[
      Color(0xFFFFF2AB),
      Color(0xFFD7F4D2),
      Color(0xFFD3ECFF),
      Color(0xFFFFE0C7),
      Color(0xFFE8DCFF),
      Color(0xFFFCD8E6),
    ];
    const darkTints = <Color>[
      Color(0xFF33412A),
      Color(0xFF1F3F3A),
      Color(0xFF213E56),
      Color(0xFF4B3522),
      Color(0xFF3A2F54),
      Color(0xFF4A2738),
    ];
    final isDark = theme.brightness == Brightness.dark;
    final tints = isDark ? darkTints : lightTints;
    return Color.alphaBlend(
      tints[id.abs() % tints.length].withValues(alpha: isDark ? 0.42 : 0.28),
      theme.surface,
    );
  }
}
