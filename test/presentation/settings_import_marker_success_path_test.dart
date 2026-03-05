import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';
import 'package:to_do_app/main.dart';
import 'package:to_do_app/presentation/settings_screen.dart';

import '../fake_repositories.dart';

class _SpyNotificationService extends NotificationService {
  int cancelAllCalls = 0;
  int syncCalls = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> syncRemindersFromDatabase({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    syncCalls++;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
  });

  test(
    'success path clears marker after post-import side effects, no startup recovery',
    () async {
      final calls = <String>[];
      final notificationService = _SpyNotificationService();
      final recoveryService = ImportRecoveryService(
        notificationService: notificationService,
      );
      final noteRepository = FakeNoteRepository();
      final todoRepository = FakeTodoRepository();

      await runImportFlowWithMarker(
        markImportStarted: recoveryService.markImportStarted,
        runImport: () async {
          calls.add('import');
        },
        runPostImportSideEffects: () async {
          await runPostImportSideEffectsInOrder(
            loadFolders: () async => calls.add('folders'),
            loadNotes: () async => calls.add('notes'),
            loadTodos: () async => calls.add('todos'),
            resyncNotifications: () async {
              calls.add('notifications');
              await notificationService.syncRemindersFromDatabase(
                noteRepository: noteRepository,
                todoRepository: todoRepository,
              );
            },
            logError: (_) {},
          );
        },
        clearImportMarker: recoveryService.clearImportMarker,
      );

      expect(calls, ['import', 'folders', 'notes', 'todos', 'notifications']);
      expect(LocalStorage.importInProgress, isFalse);
      expect(notificationService.cancelAllCalls, 0);
      expect(notificationService.syncCalls, 1);

      final recoveryResult = await recoverOrSyncRemindersOnStartup(
        noteRepository: noteRepository,
        todoRepository: todoRepository,
        notificationService: notificationService,
        importRecoveryService: recoveryService,
      );

      expect(recoveryResult, ImportRecoveryResult.none);
      expect(notificationService.cancelAllCalls, 1);
      expect(notificationService.syncCalls, 2);
    },
  );
}
