import 'package:to_do_app/domain/models/folder.dart';

abstract class FolderRepository {
  Future<List<Folder>> getFolders();
  Future<void> addFolder(Folder folder);
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(int folderId);
  Future<Set<int>> getDescendantIds(int folderId);
  Future<void> moveFolder({
    required int folderId,
    required int? newParentId,
    required int newOrder,
  });
  Future<void> deleteFolderSubtree(int folderId);
}
