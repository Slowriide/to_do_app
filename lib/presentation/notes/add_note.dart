import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';

class AddNote extends StatefulWidget {
  const AddNote({super.key});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  Future<void> _saveNote() async {
    if (_alreadySaved) return;
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final text = _textController.text.trim();

      await context.read<NoteCubit>().addNote(text, title);
      _alreadySaved = true;

      if (mounted) context.go('/providerPage');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          final title = _titleController.text.trim();
          final text = _textController.text.trim();

          await context.read<NoteCubit>().addNote(text, title);
          _alreadySaved = true;
        }
      },
      child: Scaffold(
        //Appbar
        appBar: AppBar(
          title: Text(
            'New Note',
            style: textStyle.titleLarge,
          ),
          leading: IconButton(
            onPressed: () {
              context.pop(context);
            },
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
            onPressed: _saveNote,
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
