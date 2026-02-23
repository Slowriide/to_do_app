import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/utils/note_folder_picker_modal.dart';
import 'package:to_do_app/common/widgets/folder_chips.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/todo.dart';

import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_search_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_state.dart';
import 'package:to_do_app/presentation/todos/todo_masonry_view.dart';

/// TodosView is the main screen that displays a list of ToDo items.
///
/// It supports viewing, searching, selecting, pinning/unpinning, and deleting ToDos.
/// Selection mode enables multi-selection to perform batch actions like delete or pin.
///
/// Uses TodoCubit to load and manage ToDos, and TodoSearchCubit to filter them by search query.
/// A floating action button is available to add new ToDos when not in selection mode.
class TodosView extends StatefulWidget {
  const TodosView({super.key});

  @override
  State<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends State<TodosView> {
  /// Set of currently selected ToDo IDs.
  Set<int> selectedTodos = {};

  /// Whether selection mode is active (at least one ToDo is selected).
  bool get isSelectionMode => selectedTodos.isNotEmpty;

  /// Controller for the search text input.
  final _searchController = TextEditingController();

  /// Toggles selection for a specific ToDo by its [todoId].
  void toggleSelection(int todoId) {
    setState(() {
      if (selectedTodos.contains(todoId)) {
        selectedTodos.remove(todoId);
      } else {
        selectedTodos.add(todoId);
      }
    });
  }

  /// Selects all ToDos, or clears selection if all are already selected.
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

  /// Clears all current selections.
  void clearSelection() {
    setState(() => selectedTodos.clear());
  }

  /// Deletes all currently selected ToDos.
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

  Future<void> archiveSelectedTodos() async {
    final todoCubit = context.read<TodoCubit>();
    final selected = todoCubit.state.todos
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();
    await todoCubit.archiveTodos(selected);
    clearSelection();
  }

  /// Toggles pin status of selected notes.
  ///
  /// If any selected note is unpinned, all are pinned.
  /// Otherwise, all selected notes are unpinned.
  void togglePin() async {
    final todos = context.read<TodoCubit>().state.todos;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();

    final anyUnpinned = selected.any((todo) => !todo.isPinned);
    final pinValue = anyUnpinned;

    final updated =
        selected.map((todo) => todo.copyWith(isPinned: pinValue)).toList();

    await context.read<TodoCubit>().updateTodos(updated);
    clearSelection();
  }

  Future<void> moveSelectedTodos() async {
    final selected = context
        .read<TodoCubit>()
        .state
        .todos
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();
    if (selected.isEmpty) return;

    final commonFolderIds = selected.skip(1).fold<Set<int>>(
          selected.first.folderIds.toSet(),
          (acc, todo) => acc.intersection(todo.folderIds.toSet()),
        );

    final result = await showNoteFolderPickerModal(
      context: context,
      initialSelection: commonFolderIds,
      title: 'Move selected todos to',
    );

    if (result == null) return;
    await context
        .read<TodoCubit>()
        .moveTodosToFolders(selectedTodos.toList(), result.toList());
    clearSelection();
  }

  @override
  void initState() {
    super.initState();

    context
        .read<TodoSearchCubit>()
        .setArchiveScope(TodoArchiveScope.activeOnly);
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
      drawer: MyDrawer(),
      body: NestedScrollView(
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
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/addtodo'),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
    );
  }

  /// Builds the app bar for the notes screen.
  ///
  /// The app bar changes its content and actions dynamically based on whether
  /// the user is in selection mode or not:
  /// - When notes are selected (selection mode):
  ///   - Shows the number of selected notes as the title.
  ///   - Displays action buttons for clearing selection, pinning/unpinning,
  ///     selecting all notes, and deleting selected notes.
  /// - When no notes are selected (normal mode):
  ///   - Displays the default title "Notes".
  ///   - No leading or action buttons are shown.
  ///
  /// Animations are used to smoothly transition between the different states.
  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;
    final todos = context.read<TodoCubit>().state.todos;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();
    final areAllPinned =
        selected.isNotEmpty && selected.every((n) => n.isPinned);

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
                'ToDo\'s',
                key: ValueKey('normal'),
                style: textStyle.titleLarge,
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
                        message: areAllPinned ? 'Unpin Todos' : 'Pin Todos',
                        icon: areAllPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        onPressed: togglePin,
                        valueKey: ValueKey('SelectAll'),
                      ),
                      MyTooltip(
                        message: 'Archive',
                        icon: Icons.archive_outlined,
                        onPressed: archiveSelectedTodos,
                        valueKey: ValueKey('Archive'),
                      ),
                      MyTooltip(
                        message: 'Move to Folder',
                        icon: Icons.drive_file_move_outline,
                        onPressed: moveSelectedTodos,
                        valueKey: ValueKey('Move'),
                      ),
                      MyTooltip(
                        message: 'Select All',
                        icon: Icons.select_all_outlined,
                        onPressed: selectAll,
                        valueKey: ValueKey('SelectAll'),
                      ),
                      MyTooltip(
                        message: 'Delete',
                        icon: Icons.delete_outline_outlined,
                        onPressed: deleteSelectedTodos,
                        valueKey: ValueKey('Delete'),
                      ),
                    ],
                  )
                : null)
      ],
    );
  }
}

/// Internal widget that builds the ToDo list and search input.
///
/// Displays a search field and a masonry grid of ToDos
/// filtered by search input from [TodoSearchCubit].
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
    final activeTodos = allTodos.where((todo) => !todo.isArchived).toList();
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: textController,
              builder: (context, value, _) {
                final hasSearchText = value.text.trim().isNotEmpty;
                return TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.search_rounded, color: theme.tertiary),
                    hintText: 'Search Todos',
                    suffixIcon: hasSearchText
                        ? IconButton(
                            onPressed: () {
                              textController.clear();
                              context.read<TodoSearchCubit>().clearSearch();
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.tertiary,
                            ),
                          )
                        : null,
                  ),
                  onChanged: (searchValue) {
                    context.read<TodoSearchCubit>().search(searchValue);
                  },
                );
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

                  final isTrulyEmpty = activeTodos.isEmpty;
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
                      title: 'No todos yet',
                      subtitle:
                          'Create your first task and break it into subtasks.',
                      icon: Icons.playlist_add_check_circle_rounded,
                      primaryIcon: Icons.playlist_add_rounded,
                      primaryLabel: 'Create first todo',
                      onPrimaryTap: () => context.push('/addtodo'),
                      secondaryLabel: 'Set reminder',
                      onSecondaryTap: () =>
                          context.push('/addtodo?mode=reminder'),
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
