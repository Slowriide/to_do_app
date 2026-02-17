class Folder {
  final int id;
  final String name;
  final int order;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  Folder copyWith({
    int? id,
    String? name,
    int? order,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
