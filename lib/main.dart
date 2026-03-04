import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:to_do_app/core/bootstrap/app_repositories.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/config/router/app_router.dart';
import 'package:to_do_app/core/config/theme/app_theme.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/core/notifications/pinned_note_widget_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_view_mode_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/startup_recovery_snack_host.dart';

/// Entry point of the application.
///
/// Initializes local storage, notification service, and database,
/// then injects repositories and sets up Bloc providers for state management.
///
/// Also handles theme switching and routing configuration.
Future<ImportRecoveryResult> recoverOrSyncRemindersOnStartup({
  required NoteRepository noteRepository,
  required TodoRepository todoRepository,
  NotificationService? notificationService,
  ImportRecoveryService? importRecoveryService,
  DateTime? now,
}) async {
  final notifications = notificationService ?? NotificationService();
  final recovery = importRecoveryService ??
      ImportRecoveryService(notificationService: notifications);
  final recoveryResult = await recovery.recoverIfNeeded(
    noteRepository: noteRepository,
    todoRepository: todoRepository,
    now: now,
  );
  if (recoveryResult == ImportRecoveryResult.recovered) {
    return recoveryResult;
  }
  await notifications.syncRemindersFromDatabase(
    noteRepository: noteRepository,
    todoRepository: todoRepository,
  );
  if (recoveryResult == ImportRecoveryResult.staleCleared) {
    return ImportRecoveryResult.staleCleared;
  }
  return ImportRecoveryResult.none;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local preferences storage.
  await LocalStorage.configurePrefs();

  // Initialize notification service.
  await NotificationService().init();
  await PinnedNoteWidgetService.initialize();

  final repositories = await createAppRepositories();
  final startupRecoveryResult = await recoverOrSyncRemindersOnStartup(
    noteRepository: repositories.noteRepository,
    todoRepository: repositories.todoRepository,
  );

  // Run the app with injected repositories.
  runApp(MyApp(
    noteRepo: repositories.noteRepository,
    todoRepo: repositories.todoRepository,
    folderRepo: repositories.folderRepository,
    backupService: repositories.backupService as BackupService?,
    startupRecoveryResult: startupRecoveryResult,
  ));
}

class MyApp extends StatelessWidget {
  //db injection
  final NoteRepository noteRepo;
  final TodoRepository todoRepo;
  final FolderRepository folderRepo;
  final BackupService? backupService;
  final ImportRecoveryResult startupRecoveryResult;
  const MyApp({
    super.key,
    required this.noteRepo,
    required this.todoRepo,
    required this.folderRepo,
    this.backupService,
    this.startupRecoveryResult = ImportRecoveryResult.none,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: noteRepo),
        RepositoryProvider.value(value: todoRepo),
        RepositoryProvider.value(value: folderRepo),
        RepositoryProvider<BackupService?>.value(value: backupService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => NoteCubit(noteRepo)),
          BlocProvider(create: (context) => TodoCubit(todoRepo)),
          BlocProvider(create: (context) => FolderCubit(folderRepo)),
          BlocProvider(create: (context) => FolderFilterCubit()),
          BlocProvider(create: (context) => NoteSearchCubit([])),
          BlocProvider(create: (context) => NoteViewModeCubit()),
          BlocProvider(create: (context) => TodoSearchCubit([])),
          BlocProvider(create: (context) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(builder: (context, state) {
          final themeData = AppTheme(
            isDarkMode: state.isDarkmode,
            presetId: state.presetId,
            customColorHex: state.customColorHex,
            useCustomColor: state.activeColorSource == ThemeColorSource.custom,
            backgroundPresetId: state.backgroundPresetId,
            customBackgroundHex: state.customBackgroundHex,
            useCustomBackground:
                state.activeBackgroundSource == ThemeBackgroundSource.custom,
          ).getTheme();

          return AnimatedTheme(
            data: themeData,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: MaterialApp.router(
              routerConfig: appRouter,
              theme: themeData,
              title: 'ToDo App',
              debugShowCheckedModeBanner: false,
              builder: (context, child) => StartupRecoverySnackHost(
                result: startupRecoveryResult,
                child: child ?? const SizedBox.shrink(),
              ),
              localizationsDelegates:
                  FlutterQuillLocalizations.localizationsDelegates,
              supportedLocales: FlutterQuillLocalizations.supportedLocales,
            ),
          );
        }),
      ),
    );
  }
}
