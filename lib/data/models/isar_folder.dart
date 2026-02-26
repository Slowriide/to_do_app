import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/folder.dart';

part 'isar_folder.g.dart';

@Collection()
class FolderIsar {
  Id id = Isar.autoIncrement;
  @Index()
  int? parentId;
  late String name;
  late String nameNormalized;
  late int order;
  late DateTime createdAt;

  Folder toDomain() {
    return Folder(
      id: id,
      parentId: parentId,
      name: name,
      nameNormalized: nameNormalized,
      order: order,
      createdAt: createdAt,
    );
  }

  static FolderIsar fromDomain(Folder folder) {
    return FolderIsar()
      ..id = folder.id
      ..parentId = folder.parentId
      ..name = folder.name
      ..nameNormalized = folder.nameNormalized
      ..order = folder.order
      ..createdAt = folder.createdAt;
  }
}
