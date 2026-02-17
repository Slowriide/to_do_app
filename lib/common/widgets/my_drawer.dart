// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/common/widgets/widgets.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';

/// A custom drawer widget that provides navigation options for the app.
///
/// This widget includes navigation destinations for Notes, ToDo's, Settings, and Help.
/// It also includes a bottom sheet for theme selection.

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
    final themeCubit = context.read<ThemeCubit>().state;
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 34, 0, 12),
            decoration: BoxDecoration(color: theme.surface),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "My ToDo App",
                style: textStyles.titleMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: NavigationDrawer(
              tilePadding: EdgeInsets.symmetric(horizontal: 12),
              indicatorColor: theme.onPrimary,
              selectedIndex: _getSelectedIndex(location),
              onDestinationSelected: (index) async {
                Navigator.of(context).pop();

                // Small delay to allow drawer closing animation to finish before navigation.
                await Future.delayed(const Duration(milliseconds: 250));

                if (!mounted) return;
                switch (index) {
                  case 0:
                    context.go('/providerPage');
                    break;
                  case 1:
                    context.go('/todos');
                    break;
                  case 2:
                    context.go('/settings');
                    break;
                }
              },
              children: [
                NavigationDrawerDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt_outlined),
                  label: Text('Notes'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box),
                  label: Text("ToDo's"),
                ),
                Divider(
                  indent: 27,
                  endIndent: 27,
                  color: theme.primary,
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
                NavigationDrawerDestination(
                  icon: Icon(Icons.question_mark_rounded),
                  label: Text('Help'),
                ),
                Divider(
                  indent: 27,
                  endIndent: 27,
                  color: theme.primary,
                ),
                ListTile(
                  leading: Icon(Icons.dark_mode_outlined),
                  title:
                      Text(themeCubit.isDarkmode ? 'Dark Mode' : 'Light Mode'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return MyBottomSheet();
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the index of the selected destination based on the current location.
  ///
  /// If the location is '/todos', it returns 1 (ToDo's).
  /// If the location is '/settings', it returns 2 (Settings).
  ///  Otherwise, it returns 0 (Notes).
  int _getSelectedIndex(String location) {
    if (location == '/todos') return 1;
    if (location == '/settings') return 2;
    return 0;
  }
}
