import 'package:flutter_bloc/flutter_bloc.dart';

enum FolderFilterType { all, custom }

class FolderFilter {
  final FolderFilterType type;
  final int? folderId;

  const FolderFilter._(this.type, this.folderId);

  const FolderFilter.all() : this._(FolderFilterType.all, null);
  const FolderFilter.custom(int id) : this._(FolderFilterType.custom, id);
}

class FolderFilterCubit extends Cubit<FolderFilter> {
  FolderFilterCubit() : super(const FolderFilter.all());

  void setAll() => emit(const FolderFilter.all());
  void setCustom(int folderId) => emit(FolderFilter.custom(folderId));
}
