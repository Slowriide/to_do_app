import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/notes/add_note.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildApp({
  required bool autoOpenReminder,
  DateTime Function()? nowProvider,
}) {
  final noteRepo = FakeNoteRepository(initial: const []);
  final folderRepo = FakeFolderRepository(initial: const []);
  final theme = AppTheme(isDarkMode: false).getTheme();

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => NoteCubit(noteRepo)),
      BlocProvider(create: (_) => FolderCubit(folderRepo)),
      BlocProvider(create: (_) => FolderFilterCubit()),
    ],
    child: MaterialApp(
      theme: theme,
      home: AddNote(
        autoOpenReminder: autoOpenReminder,
        nowProvider: nowProvider ?? DateTime.now,
      ),
    ),
  );
}

void main() {
  testWidgets('autoOpenReminder true opens date picker on first frame',
      (tester) async {
    await _initPrefs();
    await tester.pumpWidget(_buildApp(autoOpenReminder: true));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('autoOpenReminder false does not auto open date picker',
      (tester) async {
    await _initPrefs();
    await tester.pumpWidget(_buildApp(autoOpenReminder: false));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('shows draw sketch action on supported platforms',
      (tester) async {
    await _initPrefs();
    await tester.pumpWidget(_buildApp(autoOpenReminder: false));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
  });

  testWidgets(
      'past time today shows SnackBar and does not enable reminder chip',
      (tester) async {
    await _initPrefs();
    final fixedNow = DateTime(2026, 1, 2, 12, 0);
    await tester.pumpWidget(
      _buildApp(
        autoOpenReminder: false,
        nowProvider: () => fixedNow,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    final timeInputs = find.byType(TextFormField);
    expect(timeInputs, findsNWidgets(2));
    await tester.enterText(timeInputs.at(0), '11');
    await tester.enterText(timeInputs.at(1), '00');
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    expect(find.text('Reminder time must be in the future'), findsOneWidget);
    expect(find.text('Set reminder'), findsOneWidget);
  });
}
