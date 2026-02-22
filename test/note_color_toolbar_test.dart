import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/common/widgets/note_color_toolbar.dart';

void main() {
  testWidgets('applies selected color to text selection', (tester) async {
    final controller = quill.QuillController(
      document: quill.Document.fromJson([
        {'insert': 'Hello\n'}
      ]),
      selection: const TextSelection(baseOffset: 0, extentOffset: 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteColorToolbar(controller: controller),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Apply #f6c453'));
    await tester.pumpAndSettle();

    final delta = controller.document.toDelta().toJson();
    expect(delta.toString(), contains('color: #f6c453'));
  });
}
