import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_search_cubit.dart';
import 'package:to_do_app/presentation/notes/masonry_view.dart';

/// HomePage is the main screen that displays a list of notes.
///
/// It supports viewing, searching, selecting, pinning/unpinning, and deleting notes.
/// Selection mode allows multi-selection of notes to perform batch actions.
///
/// Uses NoteCubit to load and manage notes and NoteSearchCubit to filter notes by search query.
/// Contains a floating action button to add new notes when not in selection mode.
class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  /// Stores the set of selected note IDs.
  Set<int> selectedNotes = {};

  /// Returns true if any note is selected.
  bool get isSelectionMode => selectedNotes.isNotEmpty;

  /// Controller for the search text input.
  final _searchController = TextEditingController();

  /// Toggles selection for a note by its ID.
  void toggleSelection(int noteId) {
    setState(() {
      if (selectedNotes.contains(noteId)) {
        selectedNotes.remove(noteId);
      } else {
        selectedNotes.add(noteId);
      }
    });
  }

  /// Selects all notes if not all are selected, otherwise clears selection.
  void selectAll() {
    final allNotes = context.read<NoteCubit>().state;
    final allNotesIds = allNotes.map((note) => note.id).toSet();

    setState(() {
      if (selectedNotes.containsAll(allNotesIds)) {
        selectedNotes.clear();
      } else {
        selectedNotes.addAll(allNotesIds);
      }
    });
  }

  /// Clears all selections.
  void clearSelection() {
    setState(() => selectedNotes.clear());
  }

  /// Deletes all currently selected notes using the NoteCubit.
  void deleteSelectedNotes() {
    final noteCubit = context.read<NoteCubit>();

    // Filtrar las notas seleccionadas
    final notesToDelete = noteCubit.state
        .where((note) => selectedNotes.contains(note.id))
        .toList();

    // Eliminar todas las notas seleccionadas de una vez

    noteCubit.deleteNotes(notesToDelete);

    clearSelection();
  }

  /// Toggles pin status of selected notes.
  ///
  /// If any selected note is unpinned, all are pinned.
  /// Otherwise, all selected notes are unpinned.
  void togglePin() {
    final notes = context.read<NoteCubit>().state;
    final selected = notes.where((n) => selectedNotes.contains(n.id)).toList();

    final anyUnpinned = selected.any((n) => !n.isPinned);
    final pinValue =
        anyUnpinned; //si alguna esta sin pinnear pinea todas, si estan todas pinneadas las despinea

    final updated =
        selected.map((note) => note.copyWith(isPinned: pinValue)).toList();
    context.read<NoteCubit>().updateNotes(updated);
    clearSelection();
  }

  @override
  void initState() {
    super.initState();

    final noteCubit = context.read<NoteCubit>();
    noteCubit.loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.surface,
      drawer: MyDrawer(),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppbar(theme),
        ],
        body: _Body(
          isSelectionMode: isSelectionMode,
          selectedNotesId: selectedNotes,
          toggleSelection: toggleSelection,
          textController: _searchController,
        ),
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/addNote'),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
    );
  }

  /// Builds the app bar for the notes screen.
  ///
  /// The app bar changes its content and actions dynamically based on whether
  /// the user is in selection mode or not:
  /// - When notes are selected (selection mode):
  ///   - Shows the number of selected notes as the title.
  ///   - Displays action buttons for clearing selection, pinning/unpinning,
  ///     selecting all notes, and deleting selected notes.
  /// - When no notes are selected (normal mode):
  ///   - Displays the default title "Notes".
  ///   - No leading or action buttons are shown.
  ///
  /// Animations are used to smoothly transition between the different states.
  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;
    final notes = context.read<NoteCubit>().state;
    final selected =
        notes.where((note) => selectedNotes.contains(note.id)).toList();
    final areAllPinned =
        selected.isNotEmpty && selected.every((n) => n.isPinned);

    return SliverAppBar(
      toolbarHeight: 68,
      foregroundColor: theme.onSurface,
      backgroundColor: theme.surface,
      pinned: true,
      elevation: 0,
      centerTitle: false,
      leading: isSelectionMode
          ? MyTooltip(
              message: 'Clear Selection',
              icon: Icons.close_rounded,
              onPressed: clearSelection,
              valueKey: ValueKey('clear'),
            )
          : null,
      title: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: isSelectionMode
            ? Text(
                '${selectedNotes.length} Notes selected',
                style: textStyle.titleMedium,
                key: ValueKey('selected'),
              )
            : Text('Notes',
                key: ValueKey('normal'),
                style: textStyle.titleMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                )),
      ),
      actions: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: isSelectionMode
              ? Row(
                  children: [
                    MyTooltip(
                      message: areAllPinned ? 'Unpin Notes' : 'Pin Notes',
                      icon: areAllPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      onPressed: togglePin,
                      valueKey: ValueKey('SelectAll'),
                    ),
                    MyTooltip(
                      message: 'Select All',
                      icon: Icons.select_all_outlined,
                      onPressed: selectAll,
                      valueKey: ValueKey('SelectAll'),
                    ),
                    MyTooltip(
                        message: 'Delete',
                        icon: Icons.delete_outline_outlined,
                        onPressed: deleteSelectedNotes,
                        valueKey: ValueKey('Delete')),
                  ],
                )
              : null,
        )
      ],
    );
  }
}

/// Displays the search bar and the list of notes filtered by the search query.
/// Handles selection mode and note toggling via callbacks.
class _Body extends StatelessWidget {
  final Set<int> selectedNotesId;
  final bool isSelectionMode;
  final Function(int id) toggleSelection;
  final TextEditingController textController;
  const _Body({
    required this.isSelectionMode,
    required this.selectedNotesId,
    required this.toggleSelection,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: TextField(
            controller: textController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: theme.tertiary),
              hintText: 'Search Notes',
              suffixIcon: IconButton(
                onPressed: () {
                  textController.clear();
                  context.read<NoteSearchCubit>().clearSearch();
                },
                icon: Icon(Icons.close_rounded, color: theme.tertiary),
              ),
            ),
            onChanged: (value) {
              context.read<NoteSearchCubit>().search(value);
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: BlocBuilder<NoteSearchCubit, List<Note>>(
              builder: (context, notes) {
                return MasonryView(
                  notes: notes,
                  isSelectionMode: isSelectionMode,
                  selectedNoteIds: selectedNotesId,
                  onToggleSelect: toggleSelection,
                  onReorder: (draggedId, targetId) {
                    context
                        .read<NoteCubit>()
                        .reorderNoteByIds(draggedId, targetId);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
