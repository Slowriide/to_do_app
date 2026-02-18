import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/todos/add_todo.dart';

import 'fake_repositories.dart';

Future<void> _initPrefs() async {
  SharedPreferences.setMockInitialValues({'isDarkMode': false});
  await LocalStorage.configurePrefs();
}

Widget _buildApp({required bool autoOpenReminder}) {
  final todoRepo = FakeTodoRepository(initial: const []);
  final folderRepo = FakeFolderRepository(initial: const []);
  final theme = AppTheme(isDarkMode: false).getTheme();

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => TodoCubit(todoRepo)),
      BlocProvider(create: (_) => FolderCubit(folderRepo)),
      BlocProvider(create: (_) => FolderFilterCubit()),
    ],
    child: MaterialApp(
      theme: theme,
      home: AddTodo(autoOpenReminder: autoOpenReminder),
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
}
