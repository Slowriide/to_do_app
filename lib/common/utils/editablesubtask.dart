import 'package:flutter/widgets.dart';

class EditableSubtask {
  final int id;
  final TextEditingController controller;
  bool isCompleted;
  int order;

  EditableSubtask({
    required this.id,
    required this.controller,
    this.isCompleted = false,
    this.order = 0,
  });
}
