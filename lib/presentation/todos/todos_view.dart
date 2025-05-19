import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/domain/models/todo.dart';

import 'package:to_do_app/presentation/cubits/todo_cubit.dart';
import 'package:to_do_app/presentation/cubits/todo_search_cubit.dart';
import 'package:to_do_app/presentation/todos/todo_masonry_view.dart';

class TodosView extends StatefulWidget {
  const TodosView({super.key});

  @override
  State<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends State<TodosView> {
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
    final allTodos = context.read<TodoCubit>().state;
    setState(() {
      selectedTodos.addAll(allTodos.map((todo) => todo.id));
    });
  }

  void clearSelection() {
    setState(() => selectedTodos.clear());
  }

  void deleteSelectedTodos() {
    final todoCubit = context.read<TodoCubit>();

    // Filtrar las notas seleccionadas
    final todosToDelete = todoCubit.state
        .where((todo) => selectedTodos.contains(todo.id))
        .toList();

    // Eliminar todas las notas seleccionadas de una vez
    for (final todo in todosToDelete) {
      todoCubit.deleteTodo(todo);
    }
    clearSelection();
  }

  void togglePin() {
    final todos = context.read<TodoCubit>().state;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();

    final anyUnpinned = selected.any((todo) => !todo.isPinned);
    final pinValue = anyUnpinned;

    for (final todo in selected) {
      final updated = todo.copyWith(isPinned: pinValue);
      context.read<TodoCubit>().updateTodo(updated);
    }
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

  SliverAppBar _buildAppbar(ColorScheme theme) {
    final textStyle = Theme.of(context).textTheme;
    final todos = context.read<TodoCubit>().state;
    final selected =
        todos.where((todo) => selectedTodos.contains(todo.id)).toList();
    final areAllPinned =
        selected.isNotEmpty && selected.every((n) => n.isPinned);

    return SliverAppBar(
      foregroundColor: theme.onSurface,
      backgroundColor: Colors.black,
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
              : IconButton(
                  key: ValueKey('fav'),
                  onPressed: () {},
                  icon: Icon(Icons.favorite),
                ),
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
                return Expanded(
                  child: TodoMasonryView(
                    todos: todos.where((todo) => !todo.isSubtask).toList(),
                    isSelectionMode: isSelectionMode,
                    selectedTodoIds: selectedTodosId,
                    onToggleSelect: toggleSelection,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
