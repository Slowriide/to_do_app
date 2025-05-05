// This page provide the cubit to the view

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';
import 'package:to_do_app/presentation/todos/todos_view.dart';

class TodoPage extends StatelessWidget {
  final TodoRepository repository;
  const TodoPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoCubit(repository),
      child: const TodosView(),
    );
  }
}
