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
      folderId: 42,
    );

    final cleared = note.copyWith(reminder: null, folderId: null);

    expect(cleared.reminder, isNull);
    expect(cleared.folderId, isNull);
  });

  test('Note.copyWith keeps nullable fields when omitted', () {
    final reminder = DateTime(2026, 1, 1);
    final note = Note(
      id: 1,
      title: 'n',
      text: 't',
      reminder: reminder,
      folderId: 42,
    );

    final updated = note.copyWith(title: 'new');

    expect(updated.title, 'new');
    expect(updated.reminder, reminder);
    expect(updated.folderId, 42);
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
      text: 't',
      richTextDeltaJson: '[{"insert":"t\\n"}]',
    );

    final updated = note.copyWith(richTextDeltaJson: '[{"insert":"x\\n"}]');
    final cleared = updated.copyWith(richTextDeltaJson: null);

    expect(updated.richTextDeltaJson, '[{"insert":"x\\n"}]');
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
      folderId: 9,
    );

    final cleared = todo.copyWith(reminder: null, folderId: null);

    expect(cleared.reminder, isNull);
    expect(cleared.folderId, isNull);
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
      folderId: 9,
    );

    final updated = todo.copyWith(title: 'updated');

    expect(updated.title, 'updated');
    expect(updated.reminder, reminder);
    expect(updated.folderId, 9);
  });
}
