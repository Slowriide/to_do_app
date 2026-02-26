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
  final Set<int> _expandedFolderIds = <int>{};

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
            final tree = context.read<FolderCubit>().tree;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
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
                        onPressed: () => _createFolder(),
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
                  ...tree.map(
                    (node) => _buildFolderNodeTile(
                      node: node,
                      filter: filter,
                      depth: 0,
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

  Widget _buildFolderNodeTile({
    required FolderNode node,
    required FolderFilter filter,
    required int depth,
  }) {
    final hasChildren = node.children.isNotEmpty;
    final isExpanded = _expandedFolderIds.contains(node.folder.id);

    return Column(
      children: [
        _folderTile(
          title: node.folder.name,
          selected: filter.type == FolderFilterType.custom &&
              filter.folderId == node.folder.id,
          leadingPadding: depth * 14.0,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasChildren)
                IconButton(
                  iconSize: 18,
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedFolderIds.remove(node.folder.id);
                      } else {
                        _expandedFolderIds.add(node.folder.id);
                      }
                    });
                  },
                  icon: Icon(
                    isExpanded
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                  ),
                ),
              IconButton(
                onPressed: () => _showFolderMenu(node.folder),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          onTap: () => _selectFolder(FolderFilter.custom(node.folder.id)),
        ),
        if (hasChildren && isExpanded)
          ...node.children.map(
            (child) => _buildFolderNodeTile(
              node: child,
              filter: filter,
              depth: depth + 1,
            ),
          ),
      ],
    );
  }

  Widget _folderTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
    double leadingPadding = 0,
  }) {
    final theme = Theme.of(context).colorScheme;
    final tileForegroundColor =
        selected ? theme.onPrimaryContainer : theme.onSurfaceVariant;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(
        left: 8 + leadingPadding,
        right: 8,
      ),
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

  Future<void> _createFolder({int? parentId}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentId == null ? 'Create Folder' : 'Create Subfolder'),
        content: TextField(
          controller: controller,
          maxLength: 100,
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
    final error = await context
        .read<FolderCubit>()
        .createFolder(value, parentId: parentId);
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
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Create subfolder'),
              onTap: () => Navigator.pop(context, 'createSubfolder'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Move'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete subtree'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'createSubfolder') {
      await _createFolder(parentId: folder.id);
    } else if (action == 'move') {
      await _moveFolder(folder);
    } else if (action == 'rename') {
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
          maxLength: 100,
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

  Future<void> _moveFolder(Folder folder) async {
    final parentId = await _pickParentFolderId(folder);
    if (parentId == null || parentId == _MoveCanceled.value) return;
    final targetParentId = parentId == _MoveToRoot.value ? null : parentId;

    final error = await context.read<FolderCubit>().moveFolder(
          folderId: folder.id,
          newParentId: targetParentId,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<int?> _pickParentFolderId(Folder folder) async {
    final cubit = context.read<FolderCubit>();
    final descendants = cubit.folderScopeForFilter(folder.id);

    final candidates = context
        .read<FolderCubit>()
        .state
        .where((item) => !descendants.contains(item.id))
        .toList(growable: false)
      ..sort((a, b) {
        final parentCompare = (a.parentId ?? -1).compareTo(b.parentId ?? -1);
        if (parentCompare != 0) return parentCompare;
        return a.order.compareTo(b.order);
      });

    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Move folder to')),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Root'),
                onTap: () => Navigator.pop(context, _MoveToRoot.value),
              ),
              ...candidates.map(
                (candidate) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(candidate.name),
                  subtitle: Text(candidate.parentId == null
                      ? 'Root'
                      : 'Inside folder ${candidate.parentId}'),
                  onTap: () => Navigator.pop(context, candidate.id),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context, _MoveCanceled.value),
              ),
            ],
          ),
        );
      },
    );

    return selected;
  }

  Future<void> _deleteFolder(Folder folder) async {
    final descendants =
        await context.read<FolderCubit>().getDescendantIds(folder.id);
    final allIds = <int>{folder.id, ...descendants};

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder Subtree'),
        content: Text(
          'Delete "${folder.name}" and ${descendants.length} subfolder(s)? '
          'Notes and todos will be detached from these folders.',
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

    await context.read<FolderCubit>().deleteFolder(folder.id);
    await context.read<NoteCubit>().loadNotes();
    await context.read<TodoCubit>().loadTodos();

    final filter = context.read<FolderFilterCubit>().state;
    if (filter.type == FolderFilterType.custom &&
        filter.folderId != null &&
        allIds.contains(filter.folderId)) {
      context.read<FolderFilterCubit>().setAll();
    }
  }

  void _selectFolder(FolderFilter filter) {
    final folderFilterCubit = context.read<FolderFilterCubit>();
    switch (filter.type) {
      case FolderFilterType.all:
        folderFilterCubit.setAll();
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

abstract class _MoveCanceled {
  static const int value = -999999999;
}

abstract class _MoveToRoot {
  static const int value = -999999998;
}
