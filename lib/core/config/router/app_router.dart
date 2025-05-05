import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/todo_cubit.dart';
import 'package:to_do_app/presentation/settings_screen.dart';
import 'package:to_do_app/presentation/pages.dart';

final appRouter = GoRouter(
  initialLocation: '/providerPage',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/providerPage',
      builder: (context, state) {
        final repo = RepositoryProvider.of<NoteRepository>(context);

        return NotePage(repository: repo);
      },
    ),
    GoRoute(
      path: '/addNote',
      builder: (context, state) => const AddNote(),
    ),
    GoRoute(
      path: '/editNote',
      builder: (context, state) {
        final note = state.extra as Note;
        return EditNotePage(note: note);
      },
    ),
    GoRoute(
      path: '/todos',
      builder: (context, state) => BlocProvider.value(
        value: context.read<TodoCubit>(),
        child: TodosView(),
      ),
    ),
    GoRoute(
      path: '/todosview',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/addtodo',
      builder: (context, state) => const AddTodo(),
    ),
    GoRoute(
      path: '/edittodo',
      builder: (context, state) {
        final todo = state.extra as Todo;
        return EditTodo(todo: todo);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Settings(),
    ),
  ],
);
