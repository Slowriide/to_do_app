import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/presentation/settings_screen.dart';

void main() {
  test('post-import side effects run in deterministic order', () async {
    final calls = <String>[];

    await runPostImportSideEffectsInOrder(
      loadFolders: () async => calls.add('folders'),
      loadNotes: () async => calls.add('notes'),
      loadTodos: () async => calls.add('todos'),
      resyncNotifications: () async => calls.add('notifications'),
      logError: (_) {},
    );

    expect(calls, ['folders', 'notes', 'todos', 'notifications']);
  });
}
