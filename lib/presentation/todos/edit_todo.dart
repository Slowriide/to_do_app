import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

class EditTodo extends StatefulWidget {
  final Todo todo;
  const EditTodo({super.key, required this.todo});

  @override
  State<EditTodo> createState() => _EditTodoState();
}

class _EditTodoState extends State<EditTodo> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime? _selectedReminder;

  late List<EditableSubtask> _editableSubtasks = [];
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _selectedReminder = widget.todo.reminder;
    _selectedFolderId = widget.todo.folderId;

    final sortedSubtasks = [...widget.todo.subTasks]
      ..sort((a, b) => a.order.compareTo(b.order));
    _editableSubtasks = sortedSubtasks
        .map(
          (sub) => EditableSubtask(
            id: sub.id,
            controller: TextEditingController(text: sub.title),
            isCompleted: sub.isCompleted,
            order: sub.order,
          ),
        )
        .toList();
  }

  Future<void> _showEditOrDeleteDialog() async {
    if (_selectedReminder == null) return;

    final formattedDate =
        '${MaterialLocalizations.of(context).formatFullDate(_selectedReminder!)}\n${TimeOfDay.fromDateTime(_selectedReminder!).format(context)}';

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
                  _selectedReminder = null;
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
      _selectedReminder = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
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

  void _addSubtask() {
    setState(() {
      _editableSubtasks.add(
        EditableSubtask(
          id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
          controller: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _updateTodo() async {
    final todoCubit = context.read<TodoCubit>();
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      final reminderToSave = (_selectedReminder != null &&
              _selectedReminder!.isAfter(DateTime.now()))
          ? _selectedReminder
          : null;

      final updatedSubtask = _editableSubtasks.asMap().entries.map((entry) {
        final index = entry.key;
        final ctrl = entry.value;
        return Todo(
          id: ctrl.id,
          title: ctrl.controller.text.trim(),
          isCompleted: ctrl.isCompleted,
          subTasks: [],
          isSubtask: true,
          order: index,
        );
      }).toList();

      final updatedTodo = widget.todo.copyWith(
        title: title,
        subTasks: updatedSubtask,
        reminder: reminderToSave,
        folderId: _selectedFolderId,
      );
      if (widget.todo.reminder != null) {
        await NotificationService().cancelNotification(widget.todo.id);
      }

      if (reminderToSave != null) {
        await NotificationService().showNotification(
          id: widget.todo.id,
          title: updatedTodo.title,
          scheduledDate: reminderToSave,
        );
      }

      await todoCubit.updateTodo(updatedTodo);
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
        if (didPop && !_alreadySaved) {
          _alreadySaved = true;
          await _updateTodo();
        }
      },
      child: EditorPageScaffold(
        title: 'Edit ToDo',
        subtitle: 'Fine-tune tasks, reminders, and subtask order.',
        reminderEnabled: _selectedReminder != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: () {
          if (_selectedReminder != null) {
            _showEditOrDeleteDialog();
          } else {
            pickDateReminderDate();
          }
        },
        onBackTap: () {
          _updateTodo();
          context.go('/todos');
        },
        actionLabel: 'Save ToDo',
        onActionTap: () {
          _updateTodo();
          context.go('/todos');
        },
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
