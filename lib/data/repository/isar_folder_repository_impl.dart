import 'package:isar/isar.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
import 'package:to_do_app/data/models/isar_note.dart';
import 'package:to_do_app/data/models/isar_todo.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';

class IsarFolderRepositoryImpl implements FolderRepository {
  final Isar db;
  IsarFolderRepositoryImpl(this.db);

  @override
  Future<void> addFolder(Folder folder) async {
    final folderIsar = FolderIsar.fromDomain(folder);
    await db.writeTxn(() => db.folderIsars.put(folderIsar));
  }

  @override
  Future<void> deleteFolder(int folderId) async {
    await db.writeTxn(() => db.folderIsars.delete(folderId));
  }

  @override
  Future<void> deleteFolderSubtree(int folderId) async {
    final descendants = await getDescendantIds(folderId);
    final allIds = <int>{folderId, ...descendants};

    await db.writeTxn(() async {
      final notes = await db.noteIsars.where().findAll();
      final updatedNotes = notes
          .where((note) => note.folderIds.any(allIds.contains))
          .toList(growable: false);
      for (final note in updatedNotes) {
        note.folderIds = note.folderIds.where((id) => !allIds.contains(id)).toList();
      }
      if (updatedNotes.isNotEmpty) {
        await db.noteIsars.putAll(updatedNotes);
      }

      final todos = await db.todoIsars.where().findAll();
      final updatedTodos = todos
          .where((todo) => todo.folderIds.any(allIds.contains))
          .toList(growable: false);
      for (final todo in updatedTodos) {
        todo.folderIds = todo.folderIds.where((id) => !allIds.contains(id)).toList();
      }
      if (updatedTodos.isNotEmpty) {
        await db.todoIsars.putAll(updatedTodos);
      }

      await db.folderIsars.deleteAll(allIds.toList(growable: false));
    });
  }

  @override
  Future<List<Folder>> getFolders() async {
    final folders = await db.folderIsars.where().findAll();
    return folders.map((folder) => folder.toDomain()).toList();
  }

  @override
  Future<Set<int>> getDescendantIds(int folderId) async {
    final descendants = <int>{};
    final queue = <int>[folderId];

    while (queue.isNotEmpty) {
      final parent = queue.removeLast();
      final children = await db.folderIsars.filter().parentIdEqualTo(parent).findAll();
      for (final child in children) {
        if (descendants.add(child.id)) {
          queue.add(child.id);
        }
      }
    }

    return descendants;
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final folderIsar = FolderIsar.fromDomain(folder);
    await db.writeTxn(() => db.folderIsars.put(folderIsar));
  }

  @override
  Future<void> moveFolder({
    required int folderId,
    required int? newParentId,
    required int newOrder,
  }) async {
    final folder = await db.folderIsars.get(folderId);
    if (folder == null) return;

    folder.parentId = newParentId;
    folder.order = newOrder;
    await db.writeTxn(() => db.folderIsars.put(folder));
  }
}
