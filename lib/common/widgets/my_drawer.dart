// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 34, 0, 12),
            decoration: BoxDecoration(color: theme.surface),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'My ToDo App',
                style: textStyles.titleMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: NavigationDrawer(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorColor: theme.primaryContainer.withValues(alpha: 0.55),
              selectedIndex: _getSelectedIndex(location),
              onDestinationSelected: (index) async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 250));
                if (!mounted) return;
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/todos');
                    break;
                  case 2:
                    context.go('/archived-notes');
                    break;
                  case 3:
                    context.go('/archived-todos');
                    break;
                  case 4:
                    context.go('/settings');
                    break;
                }
              },
              children: [
                const NavigationDrawerDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt_outlined),
                  label: Text('Notes'),
                ),
                const NavigationDrawerDestination(
                  icon: Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box),
                  label: Text("ToDo's"),
                ),
                const NavigationDrawerDestination(
                  icon: Icon(Icons.archive_outlined),
                  selectedIcon: Icon(Icons.archive),
                  label: Text('Archived Notes'),
                ),
                const NavigationDrawerDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text("Archived ToDo's"),
                ),
                const NavigationDrawerDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
                const SizedBox(height: 10),
                _buildFoldersSection(context),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Appearance'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersSection(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    return BlocBuilder<FolderCubit, List<Folder>>(
      builder: (context, folders) {
        return BlocBuilder<FolderFilterCubit, FolderFilter>(
          builder: (context, filter) {
            final isAll = filter.type == FolderFilterType.all;
            final isInbox = filter.type == FolderFilterType.inbox;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHigh.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Folders',
                          style: textStyle.titleMedium?.copyWith(
                            fontSize: 18,
                            color: theme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _createFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        color: theme.onSurfaceVariant,
                        tooltip: 'Create folder',
                      ),
                    ],
                  ),
                  _folderTile(
                    title: 'All',
                    selected: isAll,
                    onTap: () => _selectFolder(const FolderFilter.all()),
                  ),
                  _folderTile(
                    title: 'Inbox',
                    selected: isInbox,
                    onTap: () => _selectFolder(const FolderFilter.inbox()),
                  ),
                  ...folders.map(
                    (folder) => _folderTile(
                      title: folder.name,
                      selected: filter.type == FolderFilterType.custom &&
                          filter.folderId == folder.id,
                      trailing: IconButton(
                        onPressed: () => _showFolderMenu(folder),
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                      onTap: () =>
                          _selectFolder(FolderFilter.custom(folder.id)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _folderTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context).colorScheme;
    final tileForegroundColor =
        selected ? theme.onPrimaryContainer : theme.onSurfaceVariant;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minLeadingWidth: 20,
      leading: Icon(
        Icons.folder_outlined,
        size: 18,
        color: tileForegroundColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: tileForegroundColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: theme.primaryContainer.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          maxLength: 32,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final error = await context.read<FolderCubit>().createFolder(value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _showFolderMenu(Folder folder) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') {
      await _renameFolder(folder);
    } else if (action == 'delete') {
      await _deleteFolder(folder);
    }
  }

  Future<void> _renameFolder(Folder folder) async {
    final controller = TextEditingController(text: folder.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          maxLength: 32,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final error =
        await context.read<FolderCubit>().renameFolder(folder.id, value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Items in "${folder.name}" will be moved to Inbox. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final noteIds = context
        .read<NoteCubit>()
        .state
        .notes
        .where((note) => note.folderId == folder.id)
        .map((note) => note.id)
        .toList();
    final todoIds = context
        .read<TodoCubit>()
        .state
        .todos
        .where((todo) => todo.folderId == folder.id)
        .map((todo) => todo.id)
        .toList();

    await context.read<NoteCubit>().moveNotesToFolder(noteIds, null);
    await context.read<TodoCubit>().moveTodosToFolder(todoIds, null);
    await context.read<FolderCubit>().deleteFolder(folder.id);

    final filter = context.read<FolderFilterCubit>().state;
    if (filter.type == FolderFilterType.custom &&
        filter.folderId == folder.id) {
      context.read<FolderFilterCubit>().setInbox();
    }
  }

  void _selectFolder(FolderFilter filter) {
    final folderFilterCubit = context.read<FolderFilterCubit>();
    switch (filter.type) {
      case FolderFilterType.all:
        folderFilterCubit.setAll();
        break;
      case FolderFilterType.inbox:
        folderFilterCubit.setInbox();
        break;
      case FolderFilterType.custom:
        folderFilterCubit.setCustom(filter.folderId!);
        break;
    }

    final location = GoRouterState.of(context).uri.toString();
    if (location != '/home' &&
        location != '/archived-notes' &&
        location != '/archived-todos' &&
        location != '/todos') {
      context.go('/home');
    }
    Navigator.of(context).pop();
  }

  int _getSelectedIndex(String location) {
    if (location == '/todos') return 1;
    if (location == '/archived-notes') return 2;
    if (location == '/archived-todos') return 3;
    if (location == '/settings') return 4;
    return 0;
  }
}
