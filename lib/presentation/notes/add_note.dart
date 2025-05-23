import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
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
  DateTime? _reminderDate;

  Future<void> pickReminderDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 6),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _reminderDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveNote() async {
    final noteCubit = context.read<NoteCubit>();
    if (_alreadySaved) return;

    _alreadySaved = true;

    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final text = _textController.text.trim();
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

      if (_reminderDate != null) {
        await NotificationService().showNotification(
          id: uniqueId,
          title: title,
          body: text,
          scheduledDate: _reminderDate!,
        );
      }

      if (_reminderDate != null) {
        await noteCubit.addNote(text, title,
            reminder: _reminderDate, id: uniqueId);
      } else {
        await noteCubit.addNote(text, title, id: uniqueId);
      }

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
          _saveNote();
        }
      },
      child: Scaffold(
        backgroundColor: theme.surface,
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
              color: theme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              onPressed: pickReminderDateTime,
              icon: Icon(
                _reminderDate != null
                    ? Icons.alarm_on
                    : Icons.alarm_add_rounded,
                color: _reminderDate != null ? Colors.green : null,
              ),
            ),
          ],
        ),

        //Body
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  minLines: 1,
                  maxLines: 3,
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: textStyle.bodyLarge,
                    alignLabelWithHint: true,
                    hintText: 'Title',
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
              minimumSize: const Size.fromHeight(50),
              foregroundColor: theme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
