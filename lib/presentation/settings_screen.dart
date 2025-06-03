import 'package:flutter/material.dart';
import 'package:to_do_app/common/widgets/my_drawer.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        elevation: 2,
      ),
      body: Center(
        child: Text(
          'Settings page coming soon!',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
