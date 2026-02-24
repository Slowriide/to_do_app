import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service_base.dart';

class NoteSketchStorageServiceImpl extends NoteSketchStorageService {
  Future<Directory> _sketchDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory('${docs.path}${Platform.pathSeparator}note_sketches');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  @override
  Future<String> savePng(Uint8List bytes) async {
    final dir = await _sketchDirectory();
    final fileName =
        'sketch_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}.png';
    final file =
        File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths.toSet()) {
      if (!isOwnedSketchPath(path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Unable to delete sketch file "$path": $e');
      }
    }
  }
}

NoteSketchStorageService createNoteSketchStorageService() {
  return NoteSketchStorageServiceImpl();
}
