import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_search_cubit.dart';
import 'package:to_do_app/presentation/notes/home_page.dart';

/// Provides the necessary Cubits for the notes feature.
///
/// This widget listens to changes in the [NoteCubit] state (list of notes)
/// and updates the [NoteSearchCubit] accordingly to keep the search results
/// in sync with the latest notes.
///
/// It then renders the [HomePage], which displays the notes UI.
class NotePage extends StatelessWidget {
  final NoteRepository repository;
  const NotePage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteCubit, List<Note>>(
      listener: (context, notes) {
        context.read<NoteSearchCubit>().updateNotes(notes);
      },
      child: const HomePage(),
    );
  }
}
