import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/core/utils/id_generator.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/repository/folder_repository.dart';

class FolderCubit extends Cubit<List<Folder>> {
  final FolderRepository repository;
  Map<int, Folder> _byId = <int, Folder>{};
  Map<int?, List<Folder>> _childrenByParent = <int?, List<Folder>>{};

  FolderCubit(this.repository) : super([]) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    final folders = await repository.getFolders();
    folders.sort((a, b) {
      final parentCompare = (a.parentId ?? -1).compareTo(b.parentId ?? -1);
      if (parentCompare != 0) return parentCompare;
      return a.order.compareTo(b.order);
    });

    _byId = {
      for (final folder in folders) folder.id: folder,
    };
    final grouped = <int?, List<Folder>>{};
    for (final folder in folders) {
      grouped.putIfAbsent(folder.parentId, () => <Folder>[]).add(folder);
    }
    for (final siblings in grouped.values) {
      siblings.sort((a, b) => a.order.compareTo(b.order));
    }
    _childrenByParent = grouped;

    emit(folders);
  }

  List<FolderNode> get tree {
    List<FolderNode> build(int? parentId) {
      final children = _childrenByParent[parentId] ?? const <Folder>[];
      return children
          .map(
            (folder) => FolderNode(
              folder: folder,
              children: build(folder.id),
            ),
          )
          .toList(growable: false);
    }

    return build(null);
  }

  Set<int> folderScopeForFilter(int folderId) {
    if (!_byId.containsKey(folderId)) return const <int>{};
    final result = <int>{folderId};
    final queue = <int>[folderId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final child in _childrenByParent[current] ?? const <Folder>[]) {
        if (result.add(child.id)) {
          queue.add(child.id);
        }
      }
    }
    return result;
  }

  bool _isNameTaken(
    String name, {
    required int? parentId,
    int? excludingId,
  }) {
    final normalized = name.trim().toLowerCase();
    return state.any((folder) {
      if (folder.parentId != parentId) return false;
      if (excludingId != null && folder.id == excludingId) return false;
      return folder.nameNormalized == normalized;
    });
  }

  Future<String?> createFolder(String name, {int? parentId}) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return 'Folder name cannot be empty';
    if (normalized.length > 100) return 'Folder name must be at most 100 chars';
    if (parentId != null && !_byId.containsKey(parentId)) {
      return 'Parent folder not found';
    }
    if (_isNameTaken(normalized, parentId: parentId)) {
      return 'Folder name already exists in this location';
    }

    final siblings =
        state.where((folder) => folder.parentId == parentId).toList(growable: false);
    final nextOrder =
        siblings.isEmpty ? 0 : siblings.map((f) => f.order).reduce((a, b) => a > b ? a : b) + 1;
    final id = IdGenerator.next();
    final folder = Folder(
      id: id,
      name: normalized,
      order: nextOrder,
      createdAt: DateTime.now(),
      parentId: parentId,
    );
    await repository.addFolder(folder);
    await loadFolders();
    return null;
  }

  Future<String?> renameFolder(int id, String newName) async {
    final normalized = newName.trim();
    if (normalized.isEmpty) return 'Folder name cannot be empty';
    if (normalized.length > 100) return 'Folder name must be at most 100 chars';
    final folder = _byId[id];
    if (folder == null) return 'Folder not found';
    if (_isNameTaken(normalized, parentId: folder.parentId, excludingId: id)) {
      return 'Folder name already exists in this location';
    }

    await repository.updateFolder(folder.copyWith(name: normalized));
    await loadFolders();
    return null;
  }

  Future<String?> moveFolder({
    required int folderId,
    required int? newParentId,
  }) async {
    final folder = _byId[folderId];
    if (folder == null) return 'Folder not found';

    if (newParentId == folder.id) {
      return 'Folder cannot be moved into itself';
    }

    if (newParentId != null) {
      final parent = _byId[newParentId];
      if (parent == null) return 'Target parent not found';
      final descendants = folderScopeForFilter(folderId);
      if (descendants.contains(newParentId)) {
        return 'Folder cannot be moved inside its own subtree';
      }
    }

    if (_isNameTaken(folder.name, parentId: newParentId, excludingId: folderId)) {
      return 'Folder name already exists in target location';
    }

    final targetSiblings = state
        .where((item) => item.parentId == newParentId && item.id != folderId)
        .toList(growable: false);
    final nextOrder = targetSiblings.isEmpty
        ? 0
        : targetSiblings.map((f) => f.order).reduce((a, b) => a > b ? a : b) + 1;

    await repository.moveFolder(
      folderId: folderId,
      newParentId: newParentId,
      newOrder: nextOrder,
    );
    await loadFolders();
    return null;
  }

  Future<Set<int>> getDescendantIds(int folderId) {
    return repository.getDescendantIds(folderId);
  }

  Future<void> deleteFolder(int id) async {
    await repository.deleteFolderSubtree(id);
    await loadFolders();
  }
}
