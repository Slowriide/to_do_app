import 'package:isar/isar.dart';
import 'package:to_do_app/data/models/isar_folder.dart';
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
  Future<List<Folder>> getFolders() async {
    final folders = await db.folderIsars.where().findAll();
    return folders.map((folder) => folder.toDomain()).toList();
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final folderIsar = FolderIsar.fromDomain(folder);
    await db.writeTxn(() => db.folderIsars.put(folderIsar));
  }
}
