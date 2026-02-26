class Folder {
  final int id;
  final String name;
  final int order;
  final DateTime createdAt;
  final int? parentId;
  final String nameNormalized;

  Folder({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
    this.parentId,
    String? nameNormalized,
  }) : nameNormalized = nameNormalized ?? name.trim().toLowerCase();

  Folder copyWith({
    int? id,
    String? name,
    int? order,
    DateTime? createdAt,
    Object? parentId = _unset,
    String? nameNormalized,
  }) {
    final nextName = name ?? this.name;
    return Folder(
      id: id ?? this.id,
      name: nextName,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      parentId: identical(parentId, _unset) ? this.parentId : parentId as int?,
      nameNormalized: nameNormalized ?? nextName.trim().toLowerCase(),
    );
  }

  static const Object _unset = Object();
}

class FolderNode {
  final Folder folder;
  final List<FolderNode> children;

  const FolderNode({
    required this.folder,
    required this.children,
  });
}
