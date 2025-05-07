import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
  }

  Future<void> _updateNote() async {
    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim(),
      text: _textController.text.trim(),
    );

    await context.read<NoteCubit>().updateNote(updatedNote);
    if (mounted) context.go('/providerPage');
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final theme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          final updatedNote = widget.note.copyWith(
            title: _titleController.text.trim(),
            text: _textController.text.trim(),
          );
          _alreadySaved = true;
          await context.read<NoteCubit>().updateNote(updatedNote);
        }
      },
      child: Scaffold(
        //Appbar
        appBar: AppBar(
          leading: IconButton(
            onPressed: _updateNote,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.primary,
            ),
          ),
        ),

        //Body
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  maxLines: 3,
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: textStyle.bodyLarge,
                    alignLabelWithHint: true,
                    hintText: 'title',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextFormField(
                    maxLines: null,
                    expands: true,
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: 'Texto',
                      alignLabelWithHint: true,
                      labelStyle: textStyle.bodyLarge,
                      hintText: 'Note',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _updateNote,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ),
    );
  }
}
