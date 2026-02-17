import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/todo.dart';

import 'package:to_do_app/presentation/cubits/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todo_search_cubit.dart';
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
    final allTodos = context.read<TodoCubit>().state;
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
  void deleteSelectedTodos() {
    final todoCubit = context.read<TodoCubit>();

    // Filtrar las notas seleccionadas
    final todosToDelete = todoCubit.state
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();

    // Eliminar todas las notas seleccionadas de una vez
    todoCubit.deleteMultiples(todosToDelete);

    clearSelection();
  }

  /// Toggles pin status of selected notes.
  ///
  /// If any selected note is unpinned, all are pinned.
  /// Otherwise, all selected notes are unpinned.
  void togglePin() async {
    final todos = context.read<TodoCubit>().state;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();

    final anyUnpinned = selected.any((todo) => !todo.isPinned);
    final pinValue = anyUnpinned;

    final updated =
        selected.map((todo) => todo.copyWith(isPinned: pinValue)).toList();

    await context.read<TodoCubit>().updateTodos(updated);
    clearSelection();
  }

  @override
  void initState() {
    super.initState();

    final todoCubit = context.read<TodoCubit>();
    todoCubit.loadTodos();
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
              child: Icon(Icons.add, color: Colors.white, size: 25),
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
    final todos = context.read<TodoCubit>().state;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();
    final areAllPinned =
        selected.isNotEmpty && selected.every((n) => n.isPinned);

    return SliverAppBar(
      toolbarHeight: 60,
      foregroundColor: theme.onSurface,
      backgroundColor: theme.surface,
      pinned: true,
      elevation: 0,
      centerTitle: true,
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
                style: textStyle.titleMedium?.copyWith(
                  fontSize: 40,
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
                        message: areAllPinned ? 'Unpin Todos' : 'Pin Todos',
                        icon: areAllPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        onPressed: togglePin,
                        valueKey: ValueKey('SelectAll'),
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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 0),
          child: TextField(
            controller: textController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: theme.onSurface),
              hintText: 'Search Todos',
              filled: true,
              fillColor: theme.secondary,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: IconButton(
                onPressed: () {
                  textController.clear();
                  context.read<TodoSearchCubit>().clearSearch();
                },
                icon: Icon(Icons.close),
              ),
            ),
            onChanged: (value) {
              context.read<TodoSearchCubit>().search(value);
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: BlocBuilder<TodoSearchCubit, List<Todo>>(
              builder: (context, todos) {
                return TodoMasonryView(
                  todos: todos.where((todo) => !todo.isSubtask).toList(),
                  isSelectionMode: isSelectionMode,
                  selectedTodoIds: selectedTodosId,
                  onToggleSelect: toggleSelection,
                  onReorder: (reorderedTodos) {
                    context.read<TodoCubit>().reorderTodos(reorderedTodos);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
