import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';

class FolderChips extends StatelessWidget {
  const FolderChips({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<FolderCubit, List<Folder>>(
      builder: (context, folders) {
        final rootFolders = folders
            .where((folder) => folder.parentId == null)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return BlocBuilder<FolderFilterCubit, FolderFilter>(
          builder: (context, filter) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      showCheckmark: false,
                      selectedColor:
                          colors.primaryContainer.withValues(alpha: 0.55),
                      side: BorderSide(
                        color: colors.outlineVariant,
                      ),
                      labelStyle: TextStyle(
                        color: filter.type == FolderFilterType.all
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      selected: filter.type == FolderFilterType.all,
                      onSelected: (_) =>
                          context.read<FolderFilterCubit>().setAll(),
                    ),
                    const SizedBox(width: 8),
                    ...rootFolders.map(
                      (folder) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(folder.name),
                          showCheckmark: false,
                          selectedColor:
                              colors.primaryContainer.withValues(alpha: 0.55),
                          side: BorderSide(
                            color: colors.outlineVariant,
                          ),
                          labelStyle: TextStyle(
                            color: filter.type == FolderFilterType.custom &&
                                    filter.folderId == folder.id
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          selected: filter.type == FolderFilterType.custom &&
                              filter.folderId == folder.id,
                          onSelected: (_) => context
                              .read<FolderFilterCubit>()
                              .setCustom(folder.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
