import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/settings_screen.dart';

import '../fake_repositories.dart';

Future<ThemeCubit> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.configurePrefs();

  final themeCubit = ThemeCubit();
  final folderCubit = FolderCubit(FakeFolderRepository());
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return RepositoryProvider<BackupService?>.value(
            value: null,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ThemeCubit>.value(value: themeCubit),
                BlocProvider<FolderCubit>.value(value: folderCubit),
                BlocProvider(create: (_) => FolderFilterCubit()),
              ],
              child: const Settings(),
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return themeCubit;
}

void main() {
  testWidgets('renders appearance controls and five presets', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Color Presets'), findsOneWidget);
    expect(find.text('Custom Accent'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);
    expect(find.text('Forest Green'), findsOneWidget);
    expect(find.text('Sunset Orange'), findsOneWidget);
    expect(find.text('Rose Red'), findsOneWidget);
    expect(find.text('Violet Indigo'), findsOneWidget);
  });

  testWidgets('tapping a preset updates selected theme state', (tester) async {
    final themeCubit = await _pumpSettings(tester);

    await tester.tap(find.text('Forest Green'));
    await tester.pumpAndSettle();

    expect(themeCubit.state.presetId, 'forestGreen');
    expect(themeCubit.state.activeColorSource, ThemeColorSource.preset);
  });

  testWidgets('valid custom hex applies custom theme state', (tester) async {
    final themeCubit = await _pumpSettings(tester);

    final applied = themeCubit.setCustomColorHex('1a73e8');

    expect(applied, isTrue);
    expect(themeCubit.state.customColorHex, '#1A73E8');
    expect(themeCubit.state.activeColorSource, ThemeColorSource.custom);
  });

  testWidgets('invalid custom hex is rejected by theme state', (tester) async {
    final themeCubit = await _pumpSettings(tester);

    final applied = themeCubit.setCustomColorHex('ZZZZZZ');

    expect(applied, isFalse);
    expect(themeCubit.state.activeColorSource, ThemeColorSource.preset);
    expect(themeCubit.state.customColorHex, isNull);
  });
}
