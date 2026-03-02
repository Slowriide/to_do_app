import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';
import 'package:to_do_app/presentation/todos/archived_todos_view.dart';

class ArchivedTodoPage extends StatefulWidget {
  const ArchivedTodoPage({super.key});

  @override
  State<ArchivedTodoPage> createState() => _ArchivedTodoPageState();
}

class _ArchivedTodoPageState extends State<ArchivedTodoPage> {
  @override
  void initState() {
    super.initState();
    final currentTodos = context.read<TodoCubit>().state.todos;
    context.read<TodoSearchCubit>().updateTodos(currentTodos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TodoCubit, TodoState>(
      listener: (context, state) {
        context.read<TodoSearchCubit>().updateTodos(state.todos);
      },
      child: const ArchivedTodosView(),
    );
  }
}
