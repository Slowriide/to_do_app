import 'dart:io';

import 'package:isar/isar.dart';
import 'package:to_do_app/core/backup/backup_service_base.dart';
import 'package:to_do_app/core/backup/backup_service_io.dart'
    if (dart.library.html) 'package:to_do_app/core/backup/backup_service_web.dart'
    as impl;
import 'package:to_do_app/core/storage/note_sketch_storage_service.dart';

export 'package:to_do_app/core/backup/backup_service_base.dart';

BackupService createBackupService(
  Isar db, {
  NoteSketchStorageService? sketchStorage,
}) {
  return impl.createBackupService(
    db,
    sketchStorage: sketchStorage,
  );
}

Future<File?> pickBackupZip() {
  return impl.pickBackupZip();
}

Future<void> shareBackupZip(File zipFile) {
  return impl.shareBackupZip(zipFile);
}
