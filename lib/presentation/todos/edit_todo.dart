import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _selectedReminder = widget.todo.reminder;

    final sordetSubtasks = [...widget.todo.subTasks]
      ..sort((a, b) => a.order.compareTo(b.order));
    _editableSubtasks = sordetSubtasks
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
        '${MaterialLocalizations.of(context).formatFullDate(_selectedReminder!)} \n ${TimeOfDay.fromDateTime(_selectedReminder!).format(context)}';

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
                  _selectedReminder = null;
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
          id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) +
              ctrl.hashCode,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          _alreadySaved = true;
          await _updateTodo();
        }
      },
      child: Scaffold(
        //appbar
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              _updateTodo();
              context.go('/todos');
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.primary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (_selectedReminder != null) {
                  _showEditOrDeleteDialog();
                } else {
                  pickDateReminderDate();
                }
              },
              icon: Icon(
                _selectedReminder != null
                    ? Icons.alarm_on
                    : Icons.alarm_add_rounded,
                color: _selectedReminder != null ? Colors.green : null,
              ),
            ),
          ],
        ),
        //body
        body: Padding(
          padding: EdgeInsets.all(16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtasks', style: textStyle.titleMedium),
                    IconButton(
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Subtask',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SubtaskItemsView(
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
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              _updateTodo();
              context.go('/todos');
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar cambios'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ),
    );
  }
}
