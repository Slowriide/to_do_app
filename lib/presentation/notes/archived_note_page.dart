import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_state.dart';
import 'package:to_do_app/presentation/notes/archived_notes_view.dart';

class ArchivedNotePage extends StatelessWidget {
  const ArchivedNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteCubit, NoteState>(
      listener: (context, state) {
        context.read<NoteSearchCubit>().updateNotes(state.notes);
      },
      child: const ArchivedNotesView(),
    );
  }
}
