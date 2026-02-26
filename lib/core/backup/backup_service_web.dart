import 'dart:io';

import 'package:isar/isar.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service.dart';

class UnsupportedBackupService extends BackupService {
  @override
  Future<File> exportBackup({bool includeMedia = true}) {
    throw UnsupportedError('Backup export is not supported on web.');
  }

  @override
  Future<void> importBackup(File zipFile, {required ImportMode mode}) {
    throw UnsupportedError('Backup import is not supported on web.');
  }
}

BackupService createBackupService(
  Isar db, {
  NoteSketchStorageService? sketchStorage,
}) {
  return UnsupportedBackupService();
}

Future<File?> pickBackupZip() {
  throw UnsupportedError('Backup import is not supported on web.');
}

Future<void> shareBackupZip(File zipFile) {
  throw UnsupportedError('Backup export is not supported on web.');
}
