// This page provide the cubit to the view

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_search_cubit.dart';
import 'package:to_do_app/presentation/notes/home_page.dart';

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
