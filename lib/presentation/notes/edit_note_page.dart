import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';

/// Screen for editing an existing note.
///
/// Allows the user to modify the note’s title and content, and optionally update
/// a reminder date and time.
///
/// Initializes with the current note data, including subtasks if any.
///
/// When saved, updates the note via the corresponding cubit, manages notifications
/// by cancelling the old reminder and scheduling a new one if set.
///
/// Also intercepts back navigation to automatically save changes if they haven’t
/// been saved yet.
///
/// Uses [PopScope] to handle back navigation with save logic.
class EditNotePage extends StatefulWidget {
  /// The note to be edited.
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  /// Tracks whether the note has already been saved to avoid duplicate saves.
  final bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _textController;

  /// Stores the currently selected reminder date and time.
  DateTime? _selectedDateReminder;
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with existing note data
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
    // Initialize reminder date from the existing note
    _selectedDateReminder = widget.note.reminder;
    _selectedFolderId = widget.note.folderId;
  }

  /// Shows a dialog that allows the user to edit or delete the existing reminder.
  ///
  /// If there is no reminder set, this method does nothing.
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

  /// Opens a date and time picker to select a new reminder.
  ///
  /// Updates [_selectedDateReminder] if a valid date and time are chosen.
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

  /// Saves the current changes to the note, updates the reminder notification,
  /// and updates the note via the [NoteCubit].
  ///
  /// If the reminder is in the past or null, it will be cleared.
  /// Cancels any previous notification before scheduling a new one.
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
      folderId: _selectedFolderId,
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
      /// Intercepts back navigation to auto-save unsaved ToDo.
      ///
      /// Prevents data loss if the user exits without manually saving.
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
        /// Form containing the title and note text input fields.
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
                BlocBuilder<FolderCubit, List<Folder>>(
                  builder: (context, folders) {
                    return DropdownButtonFormField<int?>(
                      value: _selectedFolderId,
                      decoration: const InputDecoration(
                        labelText: 'Folder',
                        border: InputBorder.none,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Inbox'),
                        ),
                        ...folders.map(
                          (folder) => DropdownMenuItem<int?>(
                            value: folder.id,
                            child: Text(folder.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFolderId = value);
                      },
                    );
                  },
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

        /// Bottom save button that commits changes and navigates back.
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              _updateNote();
              if (mounted) context.go('/providerPage');
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Note'),
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
