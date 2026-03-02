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
  errorBuilder: (context, state) {
    return _RouteDataErrorPage(
      title: 'Navigation Error',
      message: state.error?.toString() ??
          'The requested route could not be opened.',
    );
  },
  redirect: (context, state) {
    final uri = state.uri;
    if (uri.scheme != 'todoapp') return null;

    if (uri.host == 'home' || uri.host.isEmpty) {
      return '/home';
    }

    if (uri.host == 'note' && uri.pathSegments.length == 1) {
      return '/note/${uri.pathSegments.first}';
    }

    if (uri.host == 'todo' && uri.pathSegments.length == 1) {
      return '/todo/${uri.pathSegments.first}';
    }

    return '/home';
  },
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
      path: '/note/:id',
      builder: (context, state) {
        final rawId = state.pathParameters['id'];
        final noteId = int.tryParse(rawId ?? '');
        if (noteId == null) {
          return const _RouteDataErrorPage(
            title: 'Invalid Note Link',
            message: 'The requested note id is invalid.',
          );
        }
        return _NoteByIdLoaderPage(noteId: noteId);
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
      path: '/archived-todos',
      builder: (context, state) => const ArchivedTodoPage(),
    ),
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
      path: '/todo/:id',
      builder: (context, state) {
        final rawId = state.pathParameters['id'];
        final todoId = int.tryParse(rawId ?? '');
        if (todoId == null) {
          return const _RouteDataErrorPage(
            title: 'Invalid Todo Link',
            message: 'The requested todo id is invalid.',
          );
        }
        return _TodoByIdLoaderPage(todoId: todoId);
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

class _NoteByIdLoaderPage extends StatelessWidget {
  final int noteId;
  const _NoteByIdLoaderPage({required this.noteId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NoteRepository>();
    return FutureBuilder<Note?>(
      future: repo.getNoteById(noteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _RouteDataErrorPage(
            title: 'Could not load note',
            message: 'Something went wrong while loading this note.',
          );
        }

        final note = snapshot.data;
        if (note == null) {
          return const _RouteDataErrorPage(
            title: 'Note Not Found',
            message: 'This note does not exist anymore.',
          );
        }

        return EditNotePage(note: note);
      },
    );
  }
}

class _TodoByIdLoaderPage extends StatelessWidget {
  final int todoId;
  const _TodoByIdLoaderPage({required this.todoId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TodoRepository>();
    return FutureBuilder<Todo?>(
      future: repo.getTodoById(todoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _RouteDataErrorPage(
            title: 'Could not load todo',
            message: 'Something went wrong while loading this todo.',
          );
        }

        final todo = snapshot.data;
        if (todo == null) {
          return const _RouteDataErrorPage(
            title: 'Todo Not Found',
            message: 'This todo does not exist anymore.',
          );
        }

        return EditTodo(todo: todo);
      },
    );
  }
}
