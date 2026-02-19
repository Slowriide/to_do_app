import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/utils/id_generator.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';

class FolderCubit extends Cubit<List<Folder>> {
  final FolderRepository repository;
  FolderCubit(this.repository) : super([]) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    final folders = await repository.getFolders();
    folders.sort((a, b) => a.order.compareTo(b.order));
    emit(folders);
  }

  bool _isNameTaken(String name, {int? excludingId}) {
    final normalized = name.trim().toLowerCase();
    return state.any((folder) {
      if (excludingId != null && folder.id == excludingId) return false;
      return folder.name.trim().toLowerCase() == normalized;
    });
  }

  Future<String?> createFolder(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Folder name cannot be empty';
    if (normalized.length > 32) return 'Folder name must be at most 32 chars';
    if (_isNameTaken(normalized)) return 'Folder name already exists';

    final nextOrder = state.isEmpty ? 0 : state.last.order + 1;
    final id = IdGenerator.next();
    final folder = Folder(
      id: id,
      name: normalized,
      order: nextOrder,
      createdAt: DateTime.now(),
    );
    await repository.addFolder(folder);
    await loadFolders();
    return null;
  }

  Future<String?> renameFolder(int id, String newName) async {
    final normalized = newName.trim();
    if (normalized.isEmpty) return 'Folder name cannot be empty';
    if (normalized.length > 32) return 'Folder name must be at most 32 chars';
    if (_isNameTaken(normalized, excludingId: id)) {
      return 'Folder name already exists';
    }
    Folder? folder;
    for (final item in state) {
      if (item.id == id) {
        folder = item;
        break;
      }
    }
    if (folder == null) return 'Folder not found';
    await repository.updateFolder(folder.copyWith(name: normalized));
    await loadFolders();
    return null;
  }

  Future<void> deleteFolder(int id) async {
    await repository.deleteFolder(id);
    await loadFolders();
  }
}
