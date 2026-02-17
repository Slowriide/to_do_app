import 'package:isar/isar.dart';
import 'package:to_do_app/domain/models/folder.dart';

part 'isar_folder.g.dart';

@Collection()
class FolderIsar {
  Id id = Isar.autoIncrement;
  late String name;
  late int order;
  late DateTime createdAt;

  Folder toDomain() {
    return Folder(
      id: id,
      name: name,
      order: order,
      createdAt: createdAt,
    );
  }

  static FolderIsar fromDomain(Folder folder) {
    return FolderIsar()
      ..id = folder.id
      ..name = folder.name
      ..order = folder.order
      ..createdAt = folder.createdAt;
  }
}
