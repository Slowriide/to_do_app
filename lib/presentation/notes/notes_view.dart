import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/folder_chips.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/common/utils/note_folder_picker_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_state.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';

import 'package:to_do_app/presentation/notes/note_list_view.dart';
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
    final allNotes = context.read<NoteSearchCubit>().state;
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
  Future<void> deleteSelectedNotes() async {
    final noteCubit = context.read<NoteCubit>();

    final notesToDelete = noteCubit.state.notes
        .where((note) => selectedNotes.contains(note.id))
        .toList();

    if (notesToDelete.isEmpty) return;

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      itemLabel: 'note',
      count: notesToDelete.length,
    );
    if (!confirmed) return;

    await noteCubit.deleteNotes(notesToDelete);
    clearSelection();
  }

  /// Toggles pin status of selected notes.
  ///
  /// If any selected note is unpinned, all are pinned.
  /// Otherwise, all selected notes are unpinned.
  void togglePin() {
    final notes = context.read<NoteCubit>().state.notes;
    final selected = notes.where((n) => selectedNotes.contains(n.id)).toList();

    final anyUnpinned = selected.any((n) => !n.isPinned);
    final pinValue =
        anyUnpinned; //si alguna esta sin pinnear pinea todas, si estan todas pinneadas las despinea

    final updated =
        selected.map((note) => note.copyWith(isPinned: pinValue)).toList();
    context.read<NoteCubit>().updateNotes(updated);
    clearSelection();
  }

  Future<void> archiveSelectedNotes() async {
    final noteCubit = context.read<NoteCubit>();
    final selected = noteCubit.state.notes
        .where((note) => selectedNotes.contains(note.id))
        .toList();
    await noteCubit.archiveNotes(selected);
    clearSelection();
  }

  Future<void> moveSelectedNotes() async {
    final selected = context
        .read<NoteCubit>()
        .state
        .notes
        .where((note) => selectedNotes.contains(note.id))
        .toList();
    if (selected.isEmpty) return;

    final commonFolderIds = selected.skip(1).fold<Set<int>>(
          selected.first.folderIds.toSet(),
          (acc, note) => acc.intersection(note.folderIds.toSet()),
        );

    final result = await showNoteFolderPickerModal(
      context: context,
      initialSelection: commonFolderIds,
      title: 'Move selected notes to',
    );

    if (result == null || !mounted) return;
    await context
        .read<NoteCubit>()
        .moveNotesToFolders(selectedNotes.toList(), result.toList());
    clearSelection();
  }

  @override
  void initState() {
    super.initState();

    context.read<NoteSearchCubit>().setArchiveScope(ArchiveScope.activeOnly);
    final filter = context.read<FolderFilterCubit>().state;
    context.read<NoteSearchCubit>().setFolderFilter(
          filter,
          folderScopeIds: filter.type == FolderFilterType.custom
              ? context
                  .read<FolderCubit>()
                  .folderScopeForFilter(filter.folderId!)
              : null,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final viewMode = context.select((NoteViewModeCubit cubit) => cubit.state);
    return Scaffold(
      backgroundColor: theme.surface,
      drawer: MyDrawer(),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppbar(theme, viewMode),
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
  SliverAppBar _buildAppbar(ColorScheme theme, NoteViewMode viewMode) {
    final textStyle = Theme.of(context).textTheme;
    final notes = context.read<NoteCubit>().state.notes;
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
                key: ValueKey('normal'), style: textStyle.titleLarge),
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
                      message: 'Archive',
                      icon: Icons.archive_outlined,
                      onPressed: archiveSelectedNotes,
                      valueKey: ValueKey('Archive'),
                    ),
                    MyTooltip(
                      message: 'Move to Folder',
                      icon: Icons.drive_file_move_outline,
                      onPressed: moveSelectedNotes,
                      valueKey: ValueKey('Move'),
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
              : MyTooltip(
                  message: viewMode == NoteViewMode.grid
                      ? 'Show list view'
                      : 'Show grid view',
                  icon: viewMode == NoteViewMode.grid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  onPressed: () =>
                      context.read<NoteViewModeCubit>().toggle(),
                  valueKey: const ValueKey('toggleViewMode'),
                ),
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
    final allNotes = context.select((NoteCubit cubit) => cubit.state.notes);
    final activeNotes = allNotes.where((note) => !note.isArchived).toList();
    final noteStatus = context.select((NoteCubit cubit) => cubit.state.status);
    final folderFilter =
        context.select((FolderFilterCubit cubit) => cubit.state);
    final viewMode = context.select((NoteViewModeCubit cubit) => cubit.state);

    return BlocListener<FolderFilterCubit, FolderFilter>(
      listener: (context, filter) {
        context.read<NoteSearchCubit>().setFolderFilter(
              filter,
              folderScopeIds: filter.type == FolderFilterType.custom
                  ? context
                      .read<FolderCubit>()
                      .folderScopeForFilter(filter.folderId!)
                  : null,
            );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: textController,
              builder: (context, value, _) {
                final hasSearchText = value.text.trim().isNotEmpty;
                return TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.search_rounded, color: theme.tertiary),
                    hintText: 'Search Notes',
                    suffixIcon: hasSearchText
                        ? IconButton(
                            onPressed: () {
                              textController.clear();
                              context.read<NoteSearchCubit>().clearSearch();
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.tertiary,
                            ),
                          )
                        : null,
                  ),
                  onChanged: (searchValue) {
                    context.read<NoteSearchCubit>().search(searchValue);
                  },
                );
              },
            ),
          ),
          const FolderChips(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
              child: BlocBuilder<NoteSearchCubit, List<Note>>(
                builder: (context, notes) {
                  if (noteStatus == NoteStatus.loading && allNotes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (noteStatus == NoteStatus.error && allNotes.isEmpty) {
                    return Center(
                      child: FilledButton.icon(
                        onPressed: () => context.read<NoteCubit>().loadNotes(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry loading notes'),
                      ),
                    );
                  }

                  final isTrulyEmpty = activeNotes.isEmpty;
                  final hasSearch = textController.text.trim().isNotEmpty;
                  final hasFolderFilter =
                      folderFilter.type != FolderFilterType.all;
                  final isNoResults = notes.isEmpty &&
                      !isTrulyEmpty &&
                      (hasSearch || hasFolderFilter);

                  if (isTrulyEmpty) {
                    return ActivationEmptyState(
                      title: 'No notes yet',
                      subtitle: 'Capture your first idea to get started.',
                      icon: Icons.note_add_rounded,
                      primaryIcon: Icons.note_add_rounded,
                      primaryLabel: 'Create first note',
                      onPrimaryTap: () => context.push('/addNote'),
                      secondaryLabel: 'Set reminder',
                      onSecondaryTap: () =>
                          context.push('/addNote?mode=reminder'),
                    );
                  }

                  if (isNoResults) {
                    return NoResultsState(
                      title: 'No matches found',
                      subtitle: 'Try a different search or remove filters.',
                      primaryLabel: 'Clear search',
                      onPrimaryTap: () {
                        textController.clear();
                        context.read<NoteSearchCubit>().clearSearch();
                      },
                      secondaryLabel: 'Show all folders',
                      onSecondaryTap: () {
                        context.read<FolderFilterCubit>().setAll();
                      },
                    );
                  }

                  if (viewMode == NoteViewMode.list) {
                    return NoteListView(
                      key: const ValueKey('notes_list_mode'),
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
                  }

                  return MasonryView(
                    key: const ValueKey('notes_grid_mode'),
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
      ),
    );
  }
}
