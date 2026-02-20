import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/folder_chips.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/todo.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';
import 'package:to_do_app/presentation/todos/todo_masonry_view.dart';

class ArchivedTodosView extends StatefulWidget {
  const ArchivedTodosView({super.key});

  @override
  State<ArchivedTodosView> createState() => _ArchivedTodosViewState();
}

class _ArchivedTodosViewState extends State<ArchivedTodosView> {
  Set<int> selectedTodos = {};
  bool get isSelectionMode => selectedTodos.isNotEmpty;
  final _searchController = TextEditingController();

  void toggleSelection(int todoId) {
    setState(() {
      if (selectedTodos.contains(todoId)) {
        selectedTodos.remove(todoId);
      } else {
        selectedTodos.add(todoId);
      }
    });
  }

  void selectAll() {
    final allTodos = context.read<TodoSearchCubit>().state;
    final allTodosIds = allTodos.map((todo) => todo.id).toSet();
    setState(() {
      if (selectedTodos.containsAll(allTodosIds)) {
        selectedTodos.clear();
      } else {
        selectedTodos.addAll(allTodosIds);
      }
    });
  }

  void clearSelection() {
    setState(() => selectedTodos.clear());
  }

  Future<void> deleteSelectedTodos() async {
    final todoCubit = context.read<TodoCubit>();
    final todosToDelete = todoCubit.state.todos
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();
    if (todosToDelete.isEmpty) return;

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      itemLabel: 'todo',
      count: todosToDelete.length,
    );
    if (!confirmed) return;

    await todoCubit.deleteMultiples(todosToDelete);
    clearSelection();
  }

  Future<void> restoreSelectedTodos() async {
    final todoCubit = context.read<TodoCubit>();
    final todosToRestore = todoCubit.state.todos
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();
    await todoCubit.restoreTodos(todosToRestore);
    clearSelection();
  }

  @override
  void initState() {
    super.initState();
    context
        .read<TodoSearchCubit>()
        .setArchiveScope(TodoArchiveScope.archivedOnly);
    context
        .read<TodoSearchCubit>()
        .setFolderFilter(context.read<FolderFilterCubit>().state);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.surface,
      drawer: const MyDrawer(),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppbar(theme),
        ],
        body: _Body(
          isSelectionMode: isSelectionMode,
          selectedTodosId: selectedTodos,
          toggleSelection: toggleSelection,
          textController: _searchController,
        ),
      ),
    );
  }

  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;

    return SliverAppBar(
      toolbarHeight: 68,
      foregroundColor: theme.onSurface,
      backgroundColor: theme.surface,
      pinned: true,
      elevation: 0,
      centerTitle: false,
      leading: isSelectionMode
          ? MyTooltip(
              message: 'Clear Selection',
              icon: Icons.close_rounded,
              onPressed: clearSelection,
              valueKey: ValueKey('clear'),
            )
          : null,
      title: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: isSelectionMode
            ? Text(
                '${selectedTodos.length} ToDo\'s selected',
                style: textStyle.titleMedium,
                key: ValueKey('selected'),
              )
            : Text(
                'Archived ToDo\'s',
                key: ValueKey('normal'),
                style: textStyle.titleMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: isSelectionMode
              ? Row(
                  children: [
                    MyTooltip(
                      message: 'Restore',
                      icon: Icons.unarchive_outlined,
                      onPressed: restoreSelectedTodos,
                      valueKey: ValueKey('Restore'),
                    ),
                    MyTooltip(
                      message: 'Select All',
                      icon: Icons.select_all_outlined,
                      onPressed: selectAll,
                      valueKey: ValueKey('SelectAll'),
                    ),
                    MyTooltip(
                      message: 'Delete permanently',
                      icon: Icons.delete_outline_outlined,
                      onPressed: deleteSelectedTodos,
                      valueKey: ValueKey('Delete'),
                    ),
                  ],
                )
              : null,
        )
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final Set<int> selectedTodosId;
  final bool isSelectionMode;
  final Function(int id) toggleSelection;
  final TextEditingController textController;
  const _Body({
    required this.selectedTodosId,
    required this.isSelectionMode,
    required this.toggleSelection,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final allTodos = context.select((TodoCubit cubit) => cubit.state.todos);
    final archivedTodos = allTodos.where((todo) => todo.isArchived).toList();
    final todoStatus = context.select((TodoCubit cubit) => cubit.state.status);
    final folderFilter =
        context.select((FolderFilterCubit cubit) => cubit.state);

    return BlocListener<FolderFilterCubit, FolderFilter>(
      listener: (context, filter) {
        context.read<TodoSearchCubit>().setFolderFilter(filter);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: theme.tertiary),
                hintText: 'Search Archived ToDo\'s',
                suffixIcon: IconButton(
                  onPressed: () {
                    textController.clear();
                    context.read<TodoSearchCubit>().clearSearch();
                  },
                  icon: Icon(Icons.close_rounded, color: theme.tertiary),
                ),
              ),
              onChanged: (value) {
                context.read<TodoSearchCubit>().search(value);
              },
            ),
          ),
          const FolderChips(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
              child: BlocBuilder<TodoSearchCubit, List<Todo>>(
                builder: (context, todos) {
                  if (todoStatus == TodoStatus.loading && allTodos.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (todoStatus == TodoStatus.error && allTodos.isEmpty) {
                    return Center(
                      child: FilledButton.icon(
                        onPressed: () => context.read<TodoCubit>().loadTodos(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry loading todos'),
                      ),
                    );
                  }

                  final isTrulyEmpty = archivedTodos.isEmpty;
                  final hasSearch = textController.text.trim().isNotEmpty;
                  final hasFolderFilter =
                      folderFilter.type != FolderFilterType.all;
                  final visibleTodos =
                      todos.where((todo) => !todo.isSubtask).toList();
                  final isNoResults = visibleTodos.isEmpty &&
                      !isTrulyEmpty &&
                      (hasSearch || hasFolderFilter);

                  if (isTrulyEmpty) {
                    return ActivationEmptyState(
                      title: 'No archived todos',
                      subtitle: 'Archived todos will appear here.',
                      icon: Icons.archive_outlined,
                      primaryIcon: Icons.check_box_outlined,
                      primaryLabel: 'Go to todos',
                      onPrimaryTap: () => context.go('/todos'),
                      secondaryLabel: 'Create todo',
                      onSecondaryTap: () => context.push('/addtodo'),
                    );
                  }

                  if (isNoResults) {
                    return NoResultsState(
                      title: 'No matches found',
                      subtitle: 'Try a different search or remove filters.',
                      primaryLabel: 'Clear search',
                      onPrimaryTap: () {
                        textController.clear();
                        context.read<TodoSearchCubit>().clearSearch();
                      },
                      secondaryLabel: 'Show all folders',
                      onSecondaryTap: () {
                        context.read<FolderFilterCubit>().setAll();
                      },
                    );
                  }

                  return TodoMasonryView(
                    todos: visibleTodos,
                    isSelectionMode: isSelectionMode,
                    selectedTodoIds: selectedTodosId,
                    onToggleSelect: toggleSelection,
                    onReorder: (draggedId, targetId) {
                      context
                          .read<TodoCubit>()
                          .reorderTodoByIds(draggedId, targetId);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
