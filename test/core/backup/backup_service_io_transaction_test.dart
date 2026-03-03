import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/backup_service_io.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';

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

  final zipFile = File('${tempDir.path}${Platform.pathSeparator}backup_transaction.zip');
  await zipFile.writeAsBytes(encoded, flush: true);
  return zipFile;
}

Future<void> _seedExisting(Isar db) async {
  await db.writeTxn(() async {
    await db.folderIsars.put(
      FolderIsar()
        ..id = 1
        ..name = 'existing-folder'
        ..nameNormalized = 'existing-folder'
        ..parentId = null
        ..order = 0
        ..createdAt = DateTime.utc(2025, 1, 1),
    );

    await db.noteIsars.put(
      NoteIsar()
        ..id = 1
        ..title = 'existing-note'
        ..text = 'existing-note-body'
        ..isCompleted = false
        ..isPinned = false
        ..isArchived = false
        ..order = 0
        ..folderIds = <int>[1],
    );

    await db.todoIsars.put(
      TodoIsar()
        ..id = 1
        ..title = 'existing-todo'
        ..isCompleted = false
        ..isSubtask = false
        ..order = 0
        ..isPinned = false
        ..isArchived = false
        ..folderIds = <int>[1],
    );
  });
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
        'id': 50,
        'name': 'import-folder',
        'parentId': null,
        'order': 0,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ],
    'notes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 60,
        'title': 'import-note',
        'titleRichTextDeltaJson': null,
        'text': 'import-note-body',
        'richTextDeltaJson': null,
        'isCompleted': false,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'order': 0,
        'folderIds': <int>[50],
      },
    ],
    'todos': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 70,
        'title': 'import-todo',
        'titleRichTextDeltaJson': null,
        'isCompleted': false,
        'isSubtask': false,
        'order': 0,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'folderIds': <int>[50],
        'subTasks': const <Map<String, dynamic>>[],
      },
    ],
  };
}

Map<String, dynamic> _buildMergePayload() {
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
        'name': 'merge-folder',
        'parentId': null,
        'order': 0,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ],
    'notes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 101,
        'title': 'merge-note',
        'titleRichTextDeltaJson': null,
        'text': 'merge-note-body',
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
        'title': 'merge-root-todo',
        'titleRichTextDeltaJson': null,
        'isCompleted': false,
        'isSubtask': false,
        'order': 0,
        'reminder': null,
        'isPinned': false,
        'isArchived': false,
        'folderIds': <int>[100],
        'subTasks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 103,
            'title': 'merge-sub-todo',
            'titleRichTextDeltaJson': null,
            'isCompleted': false,
            'isSubtask': true,
            'order': 0,
            'reminder': null,
            'isPinned': false,
            'isArchived': false,
            'folderIds': <int>[100],
            'subTasks': const <Map<String, dynamic>>[],
          },
        ],
      },
    ],
  };
}

Future<void> _assertOnlyExistingData(Isar isar) async {
  final folders = await isar.folderIsars.where().findAll();
  final notes = await isar.noteIsars.where().findAll();
  final todos = await isar.todoIsars.where().findAll();

  expect(folders.length, 1);
  expect(notes.length, 1);
  expect(todos.length, 1);
  expect(folders.single.name, 'existing-folder');
  expect(notes.single.title, 'existing-note');
  expect(todos.single.title, 'existing-todo');
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
      // Keep test deterministic in environments without native Isar core.
      // Individual tests short-circuit when core is unavailable.
      // ignore: avoid_print
      print('Skipping Isar transaction backup tests: $e');
    }
  });

  setUp(() async {
    if (!isarCoreReady) return;
    tempDir = await Directory.systemTemp.createTemp('backup_txn_test_');
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
    'replace import rollback: failure after clear keeps pre-import data',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _buildReplacePayload());
      final service = BackupServiceImpl(
        isar,
        importHooks: BackupImportHooks(
          onCheckpoint: (checkpoint) {
            if (checkpoint == BackupImportCheckpoint.afterReplaceClear) {
              throw StateError('forced-after-clear');
            }
          },
        ),
      );

      await expectLater(
        () => service.importBackup(zip, mode: ImportMode.replace),
        throwsA(isA<BackupImportException>()),
      );
      await _assertOnlyExistingData(isar);
    },
  );

  test(
    'replace import rollback: failure after folders putAll keeps pre-import data',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _buildReplacePayload());
      final service = BackupServiceImpl(
        isar,
        importHooks: BackupImportHooks(
          onCheckpoint: (checkpoint) {
            if (checkpoint == BackupImportCheckpoint.afterFoldersPutAll) {
              throw StateError('forced-after-folders');
            }
          },
        ),
      );

      await expectLater(
        () => service.importBackup(zip, mode: ImportMode.replace),
        throwsA(isA<BackupImportException>()),
      );
      await _assertOnlyExistingData(isar);
    },
  );

  test(
    'merge import rollback: failure during todo upsert keeps DB unchanged',
    () async {
      if (!isarCoreReady) return;
      final zip = await _writeBackupZip(tempDir, _buildMergePayload());
      final service = BackupServiceImpl(
        isar,
        importHooks: BackupImportHooks(
          onCheckpoint: (checkpoint) {
            if (checkpoint == BackupImportCheckpoint.todoUpsertAfterPutAll) {
              throw StateError('forced-todo-upsert');
            }
          },
        ),
      );

      await expectLater(
        () => service.importBackup(zip, mode: ImportMode.merge),
        throwsA(isA<BackupImportException>()),
      );
      await _assertOnlyExistingData(isar);
    },
  );
}
