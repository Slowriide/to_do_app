import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/core/utils/id_generator.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

class AddTodo extends StatefulWidget {
  final bool autoOpenReminder;

  const AddTodo({
    super.key,
    this.autoOpenReminder = false,
  });

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  bool _isAlreadysaved = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late List<EditableSubtask> _editableSubtasks = [];

  DateTime? _reminderDate;
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    final filter = context.read<FolderFilterCubit>().state;
    _selectedFolderId =
        filter.type == FolderFilterType.custom ? filter.folderId : null;
    if (widget.autoOpenReminder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pickReminderDateTime();
      });
    }
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

  void _addSubtask() {
    setState(() {
      _editableSubtasks.add(EditableSubtask(
        id: DateTime.now().millisecondsSinceEpoch,
        controller: TextEditingController(),
      ));
    });
  }

  void _handleReorder(List<EditableSubtask> newOrder) {
    setState(() {
      _editableSubtasks = newOrder;
      for (var i = 0; i < _editableSubtasks.length; i++) {
        _editableSubtasks[i].order = i;
      }
    });
  }

  Future<void> _saveTodo() async {
    if (_isAlreadysaved) return;

    _isAlreadysaved = true;

    if (_formKey.currentState?.validate() ?? false) {
      final todoCubit = context.read<TodoCubit>();
      final title = _titleController.text.trim();
      final uniqueId = IdGenerator.next();
      final subtasks = _editableSubtasks.asMap().entries.map((entry) {
        final index = entry.key;
        final ctrl = entry.value;
        return Todo(
          id: IdGenerator.next(),
          title: ctrl.controller.text.trim(),
          isCompleted: ctrl.isCompleted,
          subTasks: [],
          isSubtask: true,
          order: index,
        );
      }).toList();

      if (_reminderDate != null) {
        await NotificationService().showNotification(
          id: uniqueId,
          title: title,
          scheduledDate: _reminderDate!,
        );
      }

      if (_reminderDate != null) {
        await todoCubit.addTodo(
          title,
          subtasks,
          reminder: _reminderDate,
          id: uniqueId,
          folderId: _selectedFolderId,
        );
      } else {
        await todoCubit.addTodo(
          title,
          subtasks,
          id: uniqueId,
          folderId: _selectedFolderId,
        );
      }
      if (mounted) context.go('/todos');
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
    for (final ctrl in _editableSubtasks) {
      ctrl.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isAlreadysaved) {
          _isAlreadysaved = true;
          await _saveTodo();
        }
      },
      child: EditorPageScaffold(
        title: 'Create ToDo',
        subtitle: 'Plan tasks with subtasks and optional reminders.',
        reminderEnabled: _reminderDate != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: pickReminderDateTime,
        onBackTap: () => context.go('/todos'),
        actionLabel: 'Save ToDo',
        onActionTap: _saveTodo,
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
                        hintText: 'What do you need to do?',
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Subtasks',
                            style:
                                textStyle.titleMedium?.copyWith(fontSize: 18),
                          ),
                        ),
                        Tooltip(
                          message: 'Add subtask',
                          child: IconButton(
                            onPressed: _addSubtask,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 340,
                      child: SubtaskItemsView(
                        subtasks: _editableSubtasks,
                        onToggleComplete: (index) {
                          setState(() {
                            final task = _editableSubtasks.removeAt(index);
                            task.isCompleted = !task.isCompleted;

                            if (task.isCompleted) {
                              _editableSubtasks.add(task);
                            } else {
                              _editableSubtasks.insert(0, task);
                            }
                          });
                        },
                        onDelete: (index) {
                          setState(() {
                            _editableSubtasks.removeAt(index);
                          });
                        },
                        onReorder: _handleReorder,
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
