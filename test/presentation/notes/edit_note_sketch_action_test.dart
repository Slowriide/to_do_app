import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/notes/edit_note_page.dart';

import '../../fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildApp() {
  final noteRepo = FakeNoteRepository(initial: const []);
  final folderRepo = FakeFolderRepository(initial: const []);
  final theme = AppTheme(isDarkMode: false).getTheme();

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => NoteCubit(noteRepo)),
      BlocProvider(create: (_) => FolderCubit(folderRepo)),
    ],
    child: MaterialApp(
      theme: theme,
      home: EditNotePage(
        note: Note(id: 1, title: 'title', text: 'text'),
      ),
    ),
  );
}

void main() {
  testWidgets('shows draw sketch action', (tester) async {
    await _initPrefs();
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
  });
}
