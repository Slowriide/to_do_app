import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/note_cubit.dart';

/// Screen for adding a new Note with optional reminder support.
///
/// Allows the user to input a title and content, and optionally pick a
/// reminder date and time to schedule a notification.
///
/// Generates a unique ID based on the current timestamp, and uses [NoteCubit]
/// to save the note. Also intercepts back navigation to auto-save if not already saved.
///
/// Reminder notifications are handled via [NotificationService].
///
/// Also intercepts the back navigation (pop) to automatically save the note
/// if it hasn't been saved yet.
class AddNote extends StatefulWidget {
  const AddNote({super.key});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  /// Tracks whether the note has already been saved to avoid duplicate saves.
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  /// Stores the currently selected reminder date and time.
  DateTime? _reminderDate;
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    final filter = context.read<FolderFilterCubit>().state;
    if (filter.type == FolderFilterType.custom) {
      _selectedFolderId = filter.folderId;
    } else {
      _selectedFolderId = null;
    }
  }

  /// Opens a date picker and a time picker sequentially to select
  /// the reminder date and time.
  /// Updates [_reminderDate] state if both are selected.
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

  /// Validates the form and saves the note.
  ///
  /// Generates a unique ID based on the current timestamp.
  /// If a reminder date is set, schedules a notification.
  /// Calls the NoteCubit to add the new note.
  /// Navigates back to the main notes page after saving.
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
            reminder: _reminderDate, id: uniqueId, folderId: _selectedFolderId);
      } else {
        await noteCubit.addNote(
          text,
          title,
          id: uniqueId,
          folderId: _selectedFolderId,
        );
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
      /// Intercepts back navigation to auto-save unsaved ToDo.
      ///
      /// Prevents data loss if the user exits without manually saving.
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
              // Show alarm icon filled if reminder set, outlined otherwise
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
        /// Form containing the title and note text input fields.
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

                // Multiline expanding text field for note body
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
            onPressed: _saveNote,
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
