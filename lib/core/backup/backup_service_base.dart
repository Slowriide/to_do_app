import 'dart:io';

abstract class BackupService {
  Future<File> exportBackup({bool includeMedia = true});

  Future<void> importBackup(File zipFile, {required ImportMode mode});
}

enum ImportMode { replace, merge }

class BackupFormatException implements Exception {
  final String message;

  BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupSchemaException extends BackupFormatException {
  BackupSchemaException(super.message);
}

class BackupExportException implements Exception {
  final String message;

  BackupExportException(this.message);

  @override
  String toString() => 'BackupExportException: $message';
}

class BackupImportException implements Exception {
  final String message;

  BackupImportException(this.message);

  @override
  String toString() => 'BackupImportException: $message';
}
