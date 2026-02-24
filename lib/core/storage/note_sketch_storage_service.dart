import 'package:to_do_app/core/storage/note_sketch_storage_service_base.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service_io.dart'
    if (dart.library.html) 'package:to_do_app/core/storage/note_sketch_storage_service_web.dart'
    as impl;

export 'package:to_do_app/core/storage/note_sketch_storage_service_base.dart';

NoteSketchStorageService createNoteSketchStorageService() {
  return impl.createNoteSketchStorageService();
}
