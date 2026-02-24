import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/notes/archived_notes_view.dart';
import 'package:to_do_app/presentation/notes/notes_view.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs([Map<String, Object> values = const {}]) async {
  final base = <String, Object>{'isDarkMode': false, ...values};
  SharedPreferences.setMockInitialValues(base);
  await LocalStorage.configurePrefs();
}

Widget _buildApp({
  required FakeNoteRepository noteRepo,
  required FakeTodoRepository todoRepo,
  required FakeFolderRepository folderRepo,
  required List<Note> searchSeed,
  String initialLocation = '/home',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const NotesView()),
      GoRoute(
        path: '/archived-notes',
        builder: (context, state) => const ArchivedNotesView(),
      ),
      GoRoute(
        path: '/editNote',
        builder: (context, state) => const Scaffold(body: Text('edit-note')),
      ),
      GoRoute(
        path: '/addNote',
        builder: (context, state) => const Scaffold(body: Text('add-note')),
      ),
    ],
  );

  final themeData = AppTheme(isDarkMode: false).getTheme();
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => NoteCubit(noteRepo)),
      BlocProvider(create: (_) => TodoCubit(todoRepo)),
      BlocProvider(create: (_) => FolderCubit(folderRepo)),
      BlocProvider(create: (_) => FolderFilterCubit()),
      BlocProvider(create: (_) => NoteSearchCubit(searchSeed)),
      BlocProvider(create: (_) => NoteViewModeCubit()),
      BlocProvider(create: (_) => ThemeCubit()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: themeData,
    ),
  );
}

void main() {
  final notes = [
    Note(id: 1, title: 'Active note', text: 'alpha'),
    Note(id: 2, title: 'Archived note', text: 'beta', isArchived: true),
  ];

  testWidgets('defaults to grid and toggles to list and back', (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notes_grid_mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('notes_list_mode')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('toggleViewMode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notes_list_mode')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggleViewMode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notes_grid_mode')), findsOneWidget);
  });

  testWidgets('selection mode hides layout toggle', (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('toggleViewMode')), findsOneWidget);

    await tester.longPress(find.text('Active note'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('toggleViewMode')), findsNothing);
  });

  testWidgets(
      'selected mode persists and is shared between notes and archived notes',
      (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('toggleViewMode')));
    await tester.pumpAndSettle();
    expect(LocalStorage.notesViewMode, 'list');

    await tester.pumpWidget(
      _buildApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
        initialLocation: '/archived-notes',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notes_list_mode')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggleViewMode')));
    await tester.pumpAndSettle();
    expect(LocalStorage.notesViewMode, 'grid');

    await tester.pumpWidget(
      _buildApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
        initialLocation: '/home',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notes_grid_mode')), findsOneWidget);
  });
}
