import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
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
  DateTime? _selectedDateReminder;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
    _selectedDateReminder = widget.note.reminder;
  }

  Future<void> _showEditOrDeleteDialog() async {
    if (_selectedDateReminder == null) return;

    final formattedDate =
        '${MaterialLocalizations.of(context).formatFullDate(_selectedDateReminder!)} \n ${TimeOfDay.fromDateTime(_selectedDateReminder!).format(context)}';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Programed reminder:'),
          content: Text(formattedDate),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                pickDateReminderDate();
              },
              child: Text('Edit', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateReminder = null;
                });
                context.pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickDateReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateReminder ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateReminder ?? DateTime.now(),
        ),
        initialEntryMode: TimePickerEntryMode.inputOnly,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateReminder = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _updateNote() async {
    final noteCubit = context.read<NoteCubit>();
    final reminderToSave = (_selectedDateReminder != null &&
            _selectedDateReminder!.isAfter(DateTime.now()))
        ? _selectedDateReminder
        : null;
    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim(),
      text: _textController.text.trim(),
      reminder: reminderToSave,
    );
    if (widget.note.reminder != null) {
      await NotificationService().cancelNotification(widget.note.id);
    }

    if (reminderToSave != null) {
      await NotificationService().showNotification(
        id: widget.note.id,
        title: updatedNote.title,
        body: updatedNote.text,
        scheduledDate: reminderToSave,
      );
    }

    await noteCubit.updateNote(updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final theme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          _updateNote();
        }
      },
      child: Scaffold(
        backgroundColor: theme.surface,
        //Appbar
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              _updateNote();
              if (mounted) context.go('/providerPage');
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (_selectedDateReminder != null) {
                  _showEditOrDeleteDialog();
                } else {
                  pickDateReminderDate();
                }
              },
              icon: Icon(
                _selectedDateReminder != null
                    ? Icons.alarm_on
                    : Icons.alarm_add_rounded,
                color: _selectedDateReminder != null ? Colors.green : null,
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
          child: FilledButton.icon(
            onPressed: () {
              _updateNote();
              if (mounted) context.go('/providerPage');
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: theme.surface,
              minimumSize: const Size.fromHeight(50),
              foregroundColor: theme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
