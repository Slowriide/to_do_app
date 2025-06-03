import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';

/// Screen for adding a new ToDo with optional subtasks and a reminder.
///
/// Allows the user to input a title, add/edit/reorder subtasks, and optionally
/// pick a reminder date and time to schedule a notification.
///
/// Generates a unique ID for the ToDo, and uses [TodoCubit] to save it.
/// Also intercepts back navigation to auto-save if not already saved.
///
/// Subtasks are created using [EditableSubtask] and displayed in a reorderable list.
/// Notifications are scheduled using [NotificationService].
class AddTodo extends StatefulWidget {
  const AddTodo({super.key});

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  /// Tracks whether the note has already been saved to avoid duplicate saves.
  bool _isAlreadysaved = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  /// List of editable subtasks created by the user.
  late List<EditableSubtask> _editableSubtasks = [];

  /// Stores the currently selected reminder date and time.
  DateTime? _reminderDate;

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

  /// Adds a new editable subtask to the list with a unique temporary ID.
  ///
  /// Uses [DateTime.now().millisecondsSinceEpoch] to generate the ID.
  void _addSubtask() {
    setState(() {
      _editableSubtasks.add(EditableSubtask(
        id: DateTime.now().millisecondsSinceEpoch,
        controller: TextEditingController(),
      ));
    });
  }

  /// Updates the order of subtasks after a reorder event in the UI.
  ///
  /// Sets the order property of each [EditableSubtask] accordingly.
  void _handleReorder(List<EditableSubtask> newOrder) {
    setState(() {
      _editableSubtasks = newOrder;
      for (var i = 0; i < _editableSubtasks.length; i++) {
        _editableSubtasks[i].order = i;
      }
    });
  }

  /// Saves the new ToDo with its title, optional subtasks, and reminder.
  ///
  /// - Validates the form before saving.
  /// - Generates unique ID for main ToDo and each subtask.
  /// - Schedules a notification via [NotificationService] if reminder is set.
  /// - Navigates back to ToDo list screen after saving.
  Future<void> _saveTodo() async {
    if (_isAlreadysaved) return;

    _isAlreadysaved = true;

    if (_formKey.currentState?.validate() ?? false) {
      final todoCubit = context.read<TodoCubit>();
      final title = _titleController.text.trim();
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
      final subtasks = _editableSubtasks.asMap().entries.map((entry) {
        final index = entry.key;
        final ctrl = entry.value;
        return Todo(
          id: DateTime.now().millisecondsSinceEpoch + ctrl.hashCode,
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
        await todoCubit.addTodo(title, subtasks,
            reminder: _reminderDate, id: uniqueId);
      } else {
        await todoCubit.addTodo(title, subtasks, id: uniqueId);
      }
      if (mounted) context.go('/todos');
    }
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
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      /// Intercepts back navigation to auto-save unsaved ToDo.
      ///
      /// Prevents data loss if the user exits without manually saving.
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isAlreadysaved) {
          final title = _titleController.text.trim();
          final uniqueId =
              DateTime.now().millisecondsSinceEpoch.remainder(1000000);

          final subtasks = _editableSubtasks
              .where((ctrl) => ctrl.controller.text.trim().isEmpty)
              .map(
                (ctrl) => Todo(
                  id: DateTime.now().millisecondsSinceEpoch.remainder(1000000) +
                      ctrl.hashCode,
                  title: title,
                  isCompleted: false,
                  subTasks: [],
                  isSubtask: true,
                  order: 0,
                ),
              )
              .toList();

          await context
              .read<TodoCubit>()
              .addTodo(title, subtasks, id: uniqueId);
          _isAlreadysaved = true;
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop && !_isAlreadysaved) {
            _isAlreadysaved = true;
            await _saveTodo();
          }
        },
        child: Scaffold(
          backgroundColor: theme.surface,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                context.go('/todos');
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

          /// Form containing the title and todo subtasks.
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextField(
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

          /// Bottom save button that commits changes and navigates back.
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _saveTodo,
              icon: Icon(Icons.save),
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
      ),
    );
  }
}
