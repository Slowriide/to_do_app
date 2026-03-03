import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/backup_service_io.dart';
import 'package:to_do_app/core/backup/import_recovery_service.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/presentation/settings_screen.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

Future<File> _writeBackupZip(
  Directory tempDir,
  Map<String, dynamic> payload,
) async {
  final archive = Archive();
  final bytes = utf8.encode(jsonEncode(payload));
  archive.addFile(ArchiveFile('backup.json', bytes.length, bytes));
  final encoded = ZipEncoder().encode(archive);

  final zipFile = File('${tempDir.path}${Platform.pathSeparator}backup_success.zip');
  await zipFile.writeAsBytes(encoded, flush: true);
  return zipFile;
}

Map<String, dynamic> _buildReplacePayload() {
  return <String, dynamic>{
    'metadata': <String, dynamic>{
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': '1.0.0+1',
      'platform': 'test',
      'includeMedia': false,
    },
    'folders': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 100,
        'name': 'import-folder',
        'parentId': null,
        'order': 0,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ],
    'notes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 101,
        'title': 'import-note',
        'titleRichTextDeltaJson': null,
        'text': 'import-note-body',
        'richTextDeltaJson': null,
        'isCompleted': false,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'order': 0,
        'folderIds': <int>[100],
      },
    ],
    'todos': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 102,
        'title': 'import-todo',
        'titleRichTextDeltaJson': null,
        'isCompleted': false,
        'isSubtask': false,
        'order': 0,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'folderIds': <int>[100],
        'subTasks': const <Map<String, dynamic>>[],
      },
    ],
  };
}

Future<void> _seedExisting(Isar db) async {
  await db.writeTxn(() async {
    await db.folderIsars.put(
      FolderIsar()
        ..id = 1
        ..name = 'old-folder'
        ..nameNormalized = 'old-folder'
        ..parentId = null
        ..order = 0
        ..createdAt = DateTime.utc(2025, 1, 1),
    );
    await db.noteIsars.put(
      NoteIsar()
        ..id = 2
        ..title = 'old-note'
        ..text = 'old-note-body'
        ..isCompleted = false
        ..isPinned = false
        ..isArchived = false
        ..order = 0
        ..folderIds = <int>[1],
    );
    await db.todoIsars.put(
      TodoIsar()
        ..id = 3
        ..title = 'old-todo'
        ..isCompleted = false
        ..isSubtask = false
        ..order = 0
        ..isPinned = false
        ..isArchived = false
        ..folderIds = <int>[1],
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var isarCoreReady = false;
  late Directory tempDir;
  late Isar isar;
  var isarOpened = false;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarCoreReady = true;
    } catch (e) {
      // ignore: avoid_print
      print('Skipping success replace import tests: $e');
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.configurePrefs();
    if (!isarCoreReady) return;
    tempDir = await Directory.systemTemp.createTemp('backup_success_replace_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    isar = await Isar.open(
      <CollectionSchema>[NoteIsarSchema, TodoIsarSchema, FolderIsarSchema],
      directory: tempDir.path,
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isarOpened = true;
    await _seedExisting(isar);
  });

  tearDown(() async {
    if (!isarCoreReady || !isarOpened) return;
    await isar.close(deleteFromDisk: true);
    isarOpened = false;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'replace import success persists imported entities and clears marker in flow',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _buildReplacePayload());
      final backupService = BackupServiceImpl(isar);
      final recoveryService = ImportRecoveryService();

      await runImportFlowWithMarker(
        markImportStarted: recoveryService.markImportStarted,
        runImport: () => backupService.importBackup(zip, mode: ImportMode.replace),
        runPostImportSideEffects: () async {},
        clearImportMarker: recoveryService.clearImportMarker,
      );

      expect(LocalStorage.importInProgress, isFalse);
      final folders = await isar.folderIsars.where().findAll();
      final notes = await isar.noteIsars.where().findAll();
      final todos = await isar.todoIsars.where().findAll();
      expect(folders.length, 1);
      expect(notes.length, 1);
      expect(todos.length, 1);
      expect(folders.single.name, 'import-folder');
      expect(notes.single.title, 'import-note');
      expect(todos.single.title, 'import-todo');
    },
  );
}
