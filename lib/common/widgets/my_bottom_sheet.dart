import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';

/// A custom bottom sheet widget that allows users to select a theme (light or dark).
///
/// This widget uses the [ThemeCubit] to manage the current theme state.
///  When a user selects a theme, the bottom sheet closes and the selected theme is applied.

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final themeCubit = context.read<ThemeCubit>();
    final current = themeCubit.state;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        color: theme.surface,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text('Theme'),
          Divider(thickness: 0.5),
          _ThemeOptionTile(
            title: 'Light mode',
            selected: !current.isDarkmode,
            onTap: () => themeCubit.setLightMode(),
          ),
          _ThemeOptionTile(
            title: 'Dark mode',
            selected: current.isDarkmode,
            onTap: () => themeCubit.setDarkMode(),
          ),
        ],
      ),
    );
  }
}

/// A private widget that represents a tile in the bottom sheet for selecting a theme option.
///
/// It displays the title of the theme option and an icon indicating whether it is selected.
/// When tapped, it calls the provided [onTap] function and closes the bottom sheet.

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final bool selected;
  final void Function() onTap;
  const _ThemeOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.primary)
          : Icon(Icons.circle_outlined, color: theme.primary),
      onTap: () {
        onTap();
        context.pop();
      },
    );
  }
}
