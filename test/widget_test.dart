import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/domain/models/todo.dart';

void main() {
  test('Note.toggleCompletion flips completion state', () {
    final note = Note(id: 1, title: 'n', text: 't', isCompleted: false);

    final updated = note.toggleCompletion();

    expect(updated.isCompleted, isTrue);
    expect(updated.id, 1);
    expect(updated.title, 'n');
    expect(updated.text, 't');
  });

  test('Todo.copyWith updates selected fields and preserves others', () {
    final todo = Todo(
      id: 1,
      title: 'todo',
      isCompleted: false,
      subTasks: const [],
      isSubtask: false,
      order: 0,
    );

    final updated = todo.copyWith(title: 'updated', isPinned: true);

    expect(updated.id, 1);
    expect(updated.title, 'updated');
    expect(updated.isPinned, isTrue);
    expect(updated.isCompleted, isFalse);
    expect(updated.isSubtask, isFalse);
  });
}
