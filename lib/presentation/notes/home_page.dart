import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_search_cubit.dart';
import 'package:to_do_app/presentation/notes/masonry_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final allNotes = context.read<NoteCubit>().state;
    setState(() {
      selectedNotes.addAll(allNotes.map((note) => note.id));
    });
  }

  void clearSelection() {
    setState(() => selectedNotes.clear());
  }

  void deleteSelectedNotes() {
    final noteCubit = context.read<NoteCubit>();

    // Filtrar las notas seleccionadas
    final notesToDelete = noteCubit.state
        .where((note) => selectedNotes.contains(note.id))
        .toList();

    // Eliminar todas las notas seleccionadas de una vez
    for (final note in notesToDelete) {
      noteCubit.deleteNote(note);
    }
    clearSelection();
  }

  void togglePin() {
    final notes = context.read<NoteCubit>().state;
    final selected = notes.where((n) => selectedNotes.contains(n.id)).toList();

    final anyUnpinned = selected.any((n) => !n.isPinned);
    final pinValue =
        anyUnpinned; //si alguna esta sin pinnear pinea todas, si estan todas pinneadas las despinea

    for (final note in selected) {
      final updated = note.copyWith(isPinned: pinValue);
      context.read<NoteCubit>().updateNote(updated);
    }
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
              child: Icon(Icons.add, color: Colors.white, size: 25),
            ),
    );
  }

  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;
    final notes = context.read<NoteCubit>().state;
    final selected =
        notes.where((note) => selectedNotes.contains(note.id)).toList();
    final areAllPinned =
        selected.isNotEmpty && selected.every((n) => n.isPinned);

    return SliverAppBar(
      foregroundColor: theme.onSurface,
      backgroundColor: Colors.black,
      pinned: true,
      elevation: 0,
      centerTitle: true,
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
                'Notas',
                key: ValueKey('normal'),
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
              : IconButton(
                  key: ValueKey('fav'),
                  onPressed: () {},
                  icon: Icon(Icons.favorite),
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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 0),
          child: TextField(
            controller: textController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: theme.onSurface),
              hintText: 'Search Notes',
              filled: true,
              fillColor: theme.secondary,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: IconButton(
                onPressed: () {
                  textController.clear();
                  context.read<NoteSearchCubit>().clearSearch();
                },
                icon: Icon(Icons.close),
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
                return Expanded(
                  child: MasonryView(
                    notes: notes,
                    isSelectionMode: isSelectionMode,
                    selectedNoteIds: selectedNotesId,
                    onToggleSelect: toggleSelection,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
