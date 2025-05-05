import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';

class AddTodo extends StatefulWidget {
  const AddTodo({super.key});

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  bool _isAlreadysaved = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late List<EditableSubtask> _editableSubtasks = [];

  void _addSubtask() {
    setState(() {
      _editableSubtasks.add(EditableSubtask(
        id: DateTime.now().microsecondsSinceEpoch,
        controller: TextEditingController(),
      ));
    });
  }

  void _handleReorder(List<EditableSubtask> newOrder) {
    setState(() {
      _editableSubtasks = newOrder;
    });
  }

  Future<void> _saveTodo() async {
    if (_isAlreadysaved) return;
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();

      final subtasks = _editableSubtasks
          .map(
            (ctrl) => Todo(
              id: DateTime.now().microsecondsSinceEpoch + ctrl.hashCode,
              title: ctrl.controller.text.trim(),
              isCompleted: ctrl.isCompleted,
              subTasks: [],
              isSubtask: true,
            ),
          )
          .toList();

      await context.read<TodoCubit>().addTodo(title, subtasks);
      _isAlreadysaved = true;
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
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isAlreadysaved) {
          final title = _titleController.text.trim();
          final subtasks = _editableSubtasks
              .where((ctrl) => ctrl.controller.text.trim().isEmpty)
              .map(
                (ctrl) => Todo(
                    id: DateTime.now().microsecondsSinceEpoch + ctrl.hashCode,
                    title: title,
                    isCompleted: false,
                    subTasks: [],
                    isSubtask: true),
              )
              .toList();

          await context.read<TodoCubit>().addTodo(title, subtasks);
          _isAlreadysaved = true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.primary,
            ),
          ),
        ),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _saveTodo,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ),
    );
  }
}
