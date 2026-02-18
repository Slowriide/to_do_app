import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/todos/todos_view.dart';

/// TodoPage provides the necessary cubits and dependencies for displaying ToDos.
///
/// It listens to changes in [TodoCubit] and updates the [TodoSearchCubit] accordingly,
/// ensuring that the search state stays in sync with the full list of ToDos.
///
/// Embeds [TodosView] as the main UI to display and manage ToDos.
class TodoPage extends StatelessWidget {
  final TodoRepository repository;
  const TodoPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TodoCubit, List<Todo>>(
      listener: (context, todos) {
        context.read<TodoSearchCubit>().updateTodos(todos);
      },
      child: const TodosView(),
    );
  }
}
