import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

import 'package:to_do_app/presentation/settings_screen.dart';
import 'package:to_do_app/presentation/pages.dart';

/// The app router configuration for the ToDo application using GoRouter.
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final repo = context.read<NoteRepository>();
        return NotePage(repository: repo);
      },
    ),
    GoRoute(
      path: '/addNote',
      builder: (context, state) {
        final reminderMode = state.uri.queryParameters['mode'] == 'reminder';
        return AddNote(autoOpenReminder: reminderMode);
      },
    ),
    GoRoute(
      path: '/editNote',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Note) {
          return const _RouteDataErrorPage(
            title: 'Invalid Note Route Data',
            message: 'Could not open note editor due to missing note data.',
          );
        }
        final note = extra;
        return EditNotePage(note: note);
      },
    ),
    GoRoute(
      path: '/archived-notes',
      builder: (context, state) => const ArchivedNotePage(),
    ),
    GoRoute(
        path: '/todos',
        builder: (context, state) {
          final repo = RepositoryProvider.of<TodoRepository>(context);
          return TodoPage(repository: repo);
        }),
    GoRoute(
      path: '/addtodo',
      builder: (context, state) {
        final reminderMode = state.uri.queryParameters['mode'] == 'reminder';
        return AddTodo(autoOpenReminder: reminderMode);
      },
    ),
    GoRoute(
      path: '/edittodo',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Todo) {
          return const _RouteDataErrorPage(
            title: 'Invalid Todo Route Data',
            message: 'Could not open todo editor due to missing todo data.',
          );
        }
        final todo = extra;
        return EditTodo(todo: todo);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Settings(),
    ),
  ],
);

class _RouteDataErrorPage extends StatelessWidget {
  final String title;
  final String message;
  const _RouteDataErrorPage({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 38),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
