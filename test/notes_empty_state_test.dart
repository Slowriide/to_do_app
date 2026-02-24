import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/notes/notes_view.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildNotesApp({
  required FakeNoteRepository noteRepo,
  required FakeTodoRepository todoRepo,
  required FakeFolderRepository folderRepo,
  required List<Note> searchSeed,
  FolderFilter initialFilter = const FolderFilter.all(),
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => NoteCubit(noteRepo)),
              BlocProvider(create: (_) => TodoCubit(todoRepo)),
              BlocProvider(create: (_) => FolderCubit(folderRepo)),
              BlocProvider(
                create: (_) {
                  final cubit = FolderFilterCubit();
                  if (initialFilter.type == FolderFilterType.custom) {
                    cubit.setCustom(initialFilter.folderId!);
                  }
                  return cubit;
                },
              ),
              BlocProvider(create: (_) => NoteSearchCubit(searchSeed)),
              BlocProvider(create: (_) => NoteViewModeCubit()),
              BlocProvider(create: (_) => ThemeCubit()),
            ],
            child: const NotesView(),
          );
        },
      ),
      GoRoute(
        path: '/addNote',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'none';
          return Scaffold(body: Text('add-note:$mode'));
        },
      ),
      GoRoute(
        path: '/archived-notes',
        builder: (context, state) => const Scaffold(
          body: Text('archived-notes'),
        ),
      ),
    ],
  );

  final themeData = AppTheme(isDarkMode: false).getTheme();
  return MaterialApp.router(routerConfig: router, theme: themeData);
}

void main() {
  testWidgets('shows activation empty state and routes to create first note',
      (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Create first note'), findsOneWidget);
    expect(find.text('Set reminder'), findsOneWidget);

    await tester.tap(find.text('Create first note'));
    await tester.pumpAndSettle();
    expect(find.text('add-note:none'), findsOneWidget);
  });

  testWidgets('set reminder quick action routes with reminder query',
      (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();
    expect(find.text('add-note:reminder'), findsOneWidget);
  });

  testWidgets('shows no-results state and clear search restores list',
      (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Groceries', text: 'Milk and eggs'),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('show all folders action resets folder filter and restores list',
      (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Inbox note', text: 'inbox'),
    ];
    final folders = [
      Folder(
        id: 9,
        name: 'Work',
        order: 0,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: folders);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
        initialFilter: const FolderFilter.custom(9),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);

    await tester.tap(find.text('Show all folders'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox note'), findsOneWidget);
  });

  testWidgets('active notes view excludes archived notes', (tester) async {
    await _initPrefs();
    final notes = [
      Note(id: 1, title: 'Archived', text: 'old', isArchived: true),
    ];
    final noteRepo = FakeNoteRepository(initial: notes);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: notes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.text('Archived'), findsNothing);
  });

  testWidgets('drawer navigates to archived notes route', (tester) async {
    await _initPrefs();
    final noteRepo = FakeNoteRepository(initial: const []);
    final todoRepo = FakeTodoRepository(initial: const []);
    final folderRepo = FakeFolderRepository(initial: const []);

    await tester.pumpWidget(
      _buildNotesApp(
        noteRepo: noteRepo,
        todoRepo: todoRepo,
        folderRepo: folderRepo,
        searchSeed: const [],
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archived Notes'));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    expect(find.text('archived-notes'), findsOneWidget);
  });
}
