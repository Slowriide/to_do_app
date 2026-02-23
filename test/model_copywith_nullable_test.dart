import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';

void main() {
  test('Note.copyWith can explicitly clear nullable fields', () {
    final note = Note(
      id: 1,
      title: 'n',
      text: 't',
      reminder: DateTime(2026, 1, 1),
      folderIds: const [42],
    );

    final cleared = note.copyWith(reminder: null, folderIds: const <int>[]);

    expect(cleared.reminder, isNull);
    expect(cleared.folderIds, isEmpty);
  });

  test('Note.copyWith keeps nullable fields when omitted', () {
    final reminder = DateTime(2026, 1, 1);
    final note = Note(
      id: 1,
      title: 'n',
      text: 't',
      reminder: reminder,
      folderIds: const [42],
    );

    final updated = note.copyWith(title: 'new');

    expect(updated.title, 'new');
    expect(updated.reminder, reminder);
    expect(updated.folderIds, const [42]);
  });

  test('Note.copyWith updates archived flag', () {
    final note = Note(id: 1, title: 'n', text: 't');

    final archived = note.copyWith(isArchived: true);
    final restored = archived.copyWith(isArchived: false);

    expect(archived.isArchived, isTrue);
    expect(restored.isArchived, isFalse);
  });

  test('Note.copyWith can update and clear rich text payload', () {
    final note = Note(
      id: 1,
      title: 'n',
      titleRichTextDeltaJson: '[{"insert":"n\\n"}]',
      text: 't',
      richTextDeltaJson: '[{"insert":"t\\n"}]',
    );

    final updated = note.copyWith(
      titleRichTextDeltaJson: '[{"insert":"n2\\n"}]',
      richTextDeltaJson: '[{"insert":"x\\n"}]',
    );
    final cleared = updated.copyWith(
      titleRichTextDeltaJson: null,
      richTextDeltaJson: null,
    );

    expect(updated.titleRichTextDeltaJson, '[{"insert":"n2\\n"}]');
    expect(updated.richTextDeltaJson, '[{"insert":"x\\n"}]');
    expect(cleared.titleRichTextDeltaJson, isNull);
    expect(cleared.richTextDeltaJson, isNull);
  });

  test('Todo.copyWith can explicitly clear nullable fields', () {
    final todo = Todo(
      id: 1,
      title: 'todo',
      isCompleted: false,
      subTasks: const [],
      isSubtask: false,
      order: 0,
      reminder: DateTime(2026, 1, 1),
      folderIds: const [9],
    );

    final cleared = todo.copyWith(reminder: null, folderIds: const <int>[]);

    expect(cleared.reminder, isNull);
    expect(cleared.folderIds, isEmpty);
  });

  test('Todo.copyWith keeps nullable fields when omitted', () {
    final reminder = DateTime(2026, 1, 1);
    final todo = Todo(
      id: 1,
      title: 'todo',
      isCompleted: false,
      subTasks: const [],
      isSubtask: false,
      order: 0,
      reminder: reminder,
      folderIds: const [9],
    );

    final updated = todo.copyWith(title: 'updated');

    expect(updated.title, 'updated');
    expect(updated.reminder, reminder);
    expect(updated.folderIds, const [9]);
  });

  test('Todo.copyWith updates and clears rich title payload', () {
    final todo = Todo(
      id: 1,
      title: 'todo',
      titleRichTextDeltaJson: '[{"insert":"todo\\n"}]',
      isCompleted: false,
      subTasks: const [],
      isSubtask: false,
      order: 0,
    );

    final updated = todo.copyWith(
      titleRichTextDeltaJson: '[{"insert":"new\\n"}]',
    );
    final cleared = updated.copyWith(titleRichTextDeltaJson: null);

    expect(updated.titleRichTextDeltaJson, '[{"insert":"new\\n"}]');
    expect(cleared.titleRichTextDeltaJson, isNull);
  });
}
