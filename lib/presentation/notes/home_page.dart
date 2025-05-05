import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';

import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/notes/masonry_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<int> selectedNotes = {};
  bool get isSelectionMode => selectedNotes.isNotEmpty;

  void toggleSelection(int noteId) {
    setState(() {
      if (selectedNotes.contains(noteId)) {
        selectedNotes.remove(noteId);
      } else {
        selectedNotes.add(noteId);
      }
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
        ),
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/addNote'),
              child: Icon(Icons.add),
            ),
    );
  }

  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;
    return SliverAppBar(
      foregroundColor: theme.onSurface,
      backgroundColor: Colors.black,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      leading: isSelectionMode
          ? IconButton(
              icon: Icon(Icons.close),
              onPressed: clearSelection,
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
              ? IconButton(
                  key: ValueKey('delete'),
                  onPressed: deleteSelectedNotes,
                  icon: Icon(Icons.delete_outline_outlined),
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
  const _Body({
    required this.isSelectionMode,
    required this.selectedNotesId,
    required this.toggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: BlocBuilder<NoteCubit, List<Note>>(
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
    );
  }
}
