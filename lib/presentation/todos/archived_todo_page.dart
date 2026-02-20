import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';
import 'package:to_do_app/presentation/todos/archived_todos_view.dart';

class ArchivedTodoPage extends StatelessWidget {
  const ArchivedTodoPage({super.key});

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
