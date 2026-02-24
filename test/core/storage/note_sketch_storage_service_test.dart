import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service_base.dart';

class _FakeSketchStorageService extends NoteSketchStorageService {
  @override
  Future<void> deleteFiles(Iterable<String> paths) async {}

  @override
  Future<String> savePng(Uint8List bytes) async => 'saved.png';
}

void main() {
  final service = _FakeSketchStorageService();

  test('extracts owned sketch image paths from valid delta', () {
    const delta = '''
[
  {"insert":"hello\\n"},
  {"insert":{"image":"C:/app/note_sketches/sketch_1.png"}},
  {"insert":{"image":"C:\\\\app\\\\note_sketches\\\\sketch_2.png"}},
  {"insert":{"image":"https://example.com/note_sketches/sketch.png"}}
]
''';
    final paths = service.extractOwnedSketchPathsFromDelta(delta);
    expect(paths.length, 2);
    expect(paths.any((p) => p.contains('sketch_1.png')), isTrue);
    expect(paths.any((p) => p.contains('sketch_2.png')), isTrue);
  });

  test('ignores malformed or non-image delta payloads', () {
    expect(service.extractOwnedSketchPathsFromDelta(null), isEmpty);
    expect(service.extractOwnedSketchPathsFromDelta(''), isEmpty);
    expect(service.extractOwnedSketchPathsFromDelta('{bad json'), isEmpty);

    const noImages = '''
[
  {"insert":"text\\n"},
  {"insert":{"video":"v.mp4"}}
]
''';
    expect(service.extractOwnedSketchPathsFromDelta(noImages), isEmpty);
  });

  test('filters out non-owned and remote image paths', () {
    const delta = '''
[
  {"insert":{"image":"C:/Users/me/Pictures/photo.png"}},
  {"insert":{"image":"https://cdn.site.com/sketch.png"}},
  {"insert":{"image":"C:/app/note_sketches/sketch_3.png"}}
]
''';
    final paths = service.extractOwnedSketchPathsFromDelta(delta);
    expect(paths, {'C:/app/note_sketches/sketch_3.png'});
  });
}
