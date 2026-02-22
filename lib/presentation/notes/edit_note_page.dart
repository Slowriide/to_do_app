import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/common/widgets/note_color_toolbar.dart';
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  late quill.QuillController _titleController;
  late quill.QuillController _contentController;

  DateTime? _selectedDateReminder;
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _titleController = quill.QuillController(
      document: NoteRichTextCodec.titleDocumentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentController = quill.QuillController(
      document: NoteRichTextCodec.documentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _selectedDateReminder = widget.note.reminder;
    _selectedFolderId = widget.note.folderId;
  }

  Future<void> _showEditOrDeleteDialog() async {
    if (_selectedDateReminder == null) return;

    final formattedDate =
        '${MaterialLocalizations.of(context).formatFullDate(_selectedDateReminder!)}\n${TimeOfDay.fromDateTime(_selectedDateReminder!).format(context)}';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scheduled reminder'),
          content: Text(formattedDate),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                pickDateReminderDate();
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateReminder = null;
                });
                context.pop();
              },
              child: const Text('Delete'),
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
    final title = NoteRichTextCodec.extractPlainText(_titleController.document);
    final updatedNote = widget.note.copyWith(
      title: title,
      titleRichTextDeltaJson: NoteRichTextCodec.encodeDelta(
        _titleController.document,
      ),
      text: NoteRichTextCodec.extractPlainText(_contentController.document),
      richTextDeltaJson:
          NoteRichTextCodec.encodeDelta(_contentController.document),
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

  Future<void> _saveAndGoHome() async {
    if (_alreadySaved) return;
    _alreadySaved = true;
    await _updateNote();
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _pickFolder() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (sheetContext) {
        return BlocBuilder<FolderCubit, List<Folder>>(
          builder: (context, folders) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text('Choose folder'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.layers_outlined,
                      color: _selectedFolderId == null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: const Text('All (default)'),
                    trailing: _selectedFolderId == null
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, null),
                  ),
                  ...folders.map(
                    (folder) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      trailing: _selectedFolderId == folder.id
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, folder.id),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == _selectedFolderId) return;
    setState(() => _selectedFolderId = selected);
  }

  String _folderLabel(List<Folder> folders) {
    if (_selectedFolderId == null) return 'All';
    final selected = folders.where((folder) => folder.id == _selectedFolderId);
    if (selected.isEmpty) return 'Folder';
    return selected.first.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          _alreadySaved = true;
          await _updateNote();
        }
      },
      child: EditorPageScaffold(
        title: 'Edit Note',
        subtitle: 'Update details and keep your notes organized.',
        reminderEnabled: _selectedDateReminder != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: () {
          if (_selectedDateReminder != null) {
            _showEditOrDeleteDialog();
          } else {
            pickDateReminderDate();
          }
        },
        onBackTap: _saveAndGoHome,
        actionLabel: 'Save Note',
        onActionTap: _saveAndGoHome,
        floatingActionButton: BlocBuilder<FolderCubit, List<Folder>>(
          builder: (context, folders) {
            return FloatingActionButton.extended(
              onPressed: _pickFolder,
              icon: const Icon(Icons.folder_outlined),
              label: Text(_folderLabel(folders)),
              tooltip: 'Select folder',
            );
          },
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: textStyle.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    NoteColorToolbar(controller: _titleController),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(minHeight: 70),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.24),
                        ),
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _titleController,
                        config: const quill.QuillEditorConfig(
                          placeholder: 'What is this note about?',
                          expands: false,
                          scrollable: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EditorSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: textStyle.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    NoteColorToolbar(controller: _contentController),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(minHeight: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.24),
                        ),
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _contentController,
                        config: const quill.QuillEditorConfig(
                          placeholder: 'Continue writing...',
                          expands: false,
                          scrollable: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
