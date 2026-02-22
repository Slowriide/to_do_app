import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/common/widgets/note_item.dart';
import 'package:to_do_app/domain/models/note.dart';

void main() {
  testWidgets('renders rich delta using read-only quill in note card',
      (tester) async {
    final note = Note(
      id: 1,
      title: 'Rich',
      titleRichTextDeltaJson:
          '[{"insert":"Rich ","attributes":{"bold":true}},{"insert":"title\\n"}]',
      text: 'Hello world',
      richTextDeltaJson:
          '[{"insert":"Hello ","attributes":{"color":"#f6c453"}},{"insert":"world\\n"}]',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteItem(note: note, isSelected: false),
        ),
      ),
    );

    final editors = tester
        .widgetList<quill.QuillEditor>(find.byType(quill.QuillEditor))
        .toList();
    expect(editors.length, 2);
    final titleDelta = editors.first.controller.document.toDelta().toJson();
    final delta = editors.last.controller.document.toDelta().toJson();
    expect(editors.first.controller.readOnly, isTrue);
    expect(titleDelta.toString(), contains('bold: true'));
    expect(delta.toString(), contains('color: #f6c453'));
  });

  testWidgets('falls back to plain text when rich text payload is invalid',
      (tester) async {
    final note = Note(
      id: 2,
      title: 'Fallback',
      text: 'Plain fallback',
      richTextDeltaJson: '{broken json',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteItem(note: note, isSelected: false),
        ),
      ),
    );

    final editors = tester
        .widgetList<quill.QuillEditor>(find.byType(quill.QuillEditor))
        .toList();
    final delta = editors.last.controller.document.toDelta().toJson();
    expect(delta.toString(), contains('insert: Plain fallback'));
  });
}
