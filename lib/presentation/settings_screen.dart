import 'package:flutter/material.dart';
import 'package:to_do_app/common/widgets/my_drawer.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(),
      body: Center(
        child: Text('Omg Settings Hi!'),
      ),
    );
  }
}
