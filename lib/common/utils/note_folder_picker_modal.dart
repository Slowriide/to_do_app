import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';

Future<Set<int>?> showNoteFolderPickerModal({
  required BuildContext context,
  required Set<int> initialSelection,
  String title = 'Choose folders',
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    builder: (sheetContext) {
      final draftSelection = {...initialSelection};
      return BlocBuilder<FolderCubit, List<Folder>>(
        builder: (context, folders) {
          return SafeArea(
            child: StatefulBuilder(
              builder: (context, setStateModal) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    ListTile(title: Text(title)),
                    ListTile(
                      leading: Icon(
                        Icons.layers_outlined,
                        color: draftSelection.isEmpty
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: const Text('Inbox (default)'),
                      trailing: draftSelection.isEmpty
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => setStateModal(draftSelection.clear),
                    ),
                    Expanded(
                      child: ListView(
                        children: folders
                            .map(
                              (folder) => CheckboxListTile(
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                secondary: const Icon(Icons.folder_outlined),
                                title: Text(folder.name),
                                value: draftSelection.contains(folder.id),
                                onChanged: (checked) {
                                  setStateModal(() {
                                    if (checked ?? false) {
                                      draftSelection.add(folder.id);
                                    } else {
                                      draftSelection.remove(folder.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext, draftSelection),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
