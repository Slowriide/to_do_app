import 'package:flutter/material.dart';

class MyTooltip extends StatelessWidget {
  final void Function()? onPressed;
  final String message;
  final IconData icon;
  final ValueKey? valueKey;
  const MyTooltip({
    super.key,
    this.onPressed,
    required this.message,
    required this.icon,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: IconButton(
        key: valueKey,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
