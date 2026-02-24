import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/folder_chips.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_state.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/notes/note_list_view.dart';
import 'package:to_do_app/presentation/notes/masonry_view.dart';

class ArchivedNotesView extends StatefulWidget {
  const ArchivedNotesView({super.key});

  @override
  State<ArchivedNotesView> createState() => _ArchivedNotesViewState();
}

class _ArchivedNotesViewState extends State<ArchivedNotesView> {
  Set<int> selectedNotes = {};
  bool get isSelectionMode => selectedNotes.isNotEmpty;
  final _searchController = TextEditingController();

  void toggleSelection(int noteId) {
    setState(() {
      if (selectedNotes.contains(noteId)) {
        selectedNotes.remove(noteId);
      } else {
        selectedNotes.add(noteId);
      }
    });
  }

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

  void clearSelection() {
    setState(() => selectedNotes.clear());
  }

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

  Future<void> restoreSelectedNotes() async {
    final noteCubit = context.read<NoteCubit>();
    final notesToRestore = noteCubit.state.notes
        .where((note) => selectedNotes.contains(note.id))
        .toList();
    await noteCubit.restoreNotes(notesToRestore);
    clearSelection();
  }

  @override
  void initState() {
    super.initState();
    context.read<NoteSearchCubit>().setArchiveScope(ArchiveScope.archivedOnly);
    context
        .read<NoteSearchCubit>()
        .setFolderFilter(context.read<FolderFilterCubit>().state);
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
      drawer: const MyDrawer(),
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
    );
  }

  SliverAppBar _buildAppbar(ColorScheme theme, NoteViewMode viewMode) {
    final textStyle = Theme.of(context).textTheme;

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
            : Text(
                'Archived Notes',
                key: ValueKey('normal'),
                style: textStyle.titleLarge,
              ),
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
                      message: 'Restore',
                      icon: Icons.unarchive_outlined,
                      onPressed: restoreSelectedNotes,
                      valueKey: ValueKey('Restore'),
                    ),
                    MyTooltip(
                      message: 'Select All',
                      icon: Icons.select_all_outlined,
                      onPressed: selectAll,
                      valueKey: ValueKey('SelectAll'),
                    ),
                    MyTooltip(
                      message: 'Delete permanently',
                      icon: Icons.delete_outline_outlined,
                      onPressed: deleteSelectedNotes,
                      valueKey: ValueKey('Delete'),
                    ),
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
    final archivedNotes = allNotes.where((note) => note.isArchived).toList();
    final noteStatus = context.select((NoteCubit cubit) => cubit.state.status);
    final folderFilter =
        context.select((FolderFilterCubit cubit) => cubit.state);
    final viewMode = context.select((NoteViewModeCubit cubit) => cubit.state);

    return BlocListener<FolderFilterCubit, FolderFilter>(
      listener: (context, filter) {
        context.read<NoteSearchCubit>().setFolderFilter(filter);
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
                    hintText: 'Search Archived Notes',
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

                  final isTrulyEmpty = archivedNotes.isEmpty;
                  final hasSearch = textController.text.trim().isNotEmpty;
                  final hasFolderFilter =
                      folderFilter.type != FolderFilterType.all;
                  final isNoResults = notes.isEmpty &&
                      !isTrulyEmpty &&
                      (hasSearch || hasFolderFilter);

                  if (isTrulyEmpty) {
                    return ActivationEmptyState(
                      title: 'No archived notes',
                      subtitle: 'Archived notes will appear here.',
                      icon: Icons.archive_outlined,
                      primaryIcon: Icons.note_alt_outlined,
                      primaryLabel: 'Go to notes',
                      onPrimaryTap: () => context.go('/home'),
                      secondaryLabel: 'Create note',
                      onSecondaryTap: () => context.push('/addNote'),
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
