import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/editablesubtask.dart';
import 'package:to_do_app/common/widgets/subtasks_items_view.dart';
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

  late List<EditableSubtask> _editableSubtasks = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);

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
          id: DateTime.now().microsecondsSinceEpoch,
          controller: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _updateTodo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();

      final updatedSubtask = _editableSubtasks.asMap().entries.map((entry) {
        final index = entry.key;
        final ctrl = entry.value;
        return Todo(
          id: DateTime.now().microsecondsSinceEpoch + ctrl.hashCode,
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
      );

      await context.read<TodoCubit>().updateTodo(updatedTodo);
      if (mounted) {
        context.go('/todos');
      }
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
            onPressed: _updateTodo,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.primary,
            ),
          ),
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
            onPressed: _updateTodo,
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
