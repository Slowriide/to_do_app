import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folder_filter_cubit.dart';
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
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    final filter = context.read<FolderFilterCubit>().state;
    _selectedFolderId =
        filter.type == FolderFilterType.custom ? filter.folderId : null;
  }

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
        await noteCubit.addNote(
          text,
          title,
          reminder: _reminderDate,
          id: uniqueId,
          folderId: _selectedFolderId,
        );
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
                          ? Theme.of(context).colorScheme.onPrimary
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
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          await _saveNote();
        }
      },
      child: EditorPageScaffold(
        title: 'Create Note',
        subtitle: 'Capture ideas quickly with a clean writing space.',
        reminderEnabled: _reminderDate != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: pickReminderDateTime,
        onBackTap: () => context.pop(),
        actionLabel: 'Save Note',
        onActionTap: _saveNote,
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
                    TextFormField(
                      minLines: 1,
                      maxLines: 3,
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What is this note about?',
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
                    TextFormField(
                      minLines: 10,
                      maxLines: 16,
                      controller: _textController,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: 'Content',
                        hintText: 'Start writing your note...',
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
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
