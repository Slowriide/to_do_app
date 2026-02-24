import 'dart:typed_data';

import 'package:to_do_app/core/storage/note_sketch_storage_service_base.dart';

class NoteSketchStorageServiceImpl extends NoteSketchStorageService {
  @override
  Future<String> savePng(Uint8List bytes) {
    throw UnsupportedError('Sketch storage is not supported on web.');
  }

  @override
  Future<void> deleteFiles(Iterable<String> paths) async {}
}

NoteSketchStorageService createNoteSketchStorageService() {
  return NoteSketchStorageServiceImpl();
}
