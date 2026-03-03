import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/domain/repository/todo_repository.dart';

class ImportRecoveryService {
  final NotificationService notificationService;

  ImportRecoveryService({
    NotificationService? notificationService,
  }) : notificationService = notificationService ?? NotificationService();

  Future<void> markImportStarted() async {
    await LocalStorage.markImportInProgress();
  }

  Future<void> clearImportMarker() async {
    await LocalStorage.clearImportInProgress();
  }

  Future<bool> recoverIfNeeded({
    required NoteRepository noteRepository,
    required TodoRepository todoRepository,
  }) async {
    if (!LocalStorage.importInProgress) {
      return false;
    }

    await notificationService.cancelAll();
    await notificationService.syncRemindersFromDatabase(
      noteRepository: noteRepository,
      todoRepository: todoRepository,
    );
    await clearImportMarker();
    return true;
  }
}
