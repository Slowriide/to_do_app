import 'package:flutter/material.dart';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/domain/models/note.dart';

class NoteItem extends StatelessWidget {
  final Note note;
  final bool isSelected;

  const NoteItem({
    super.key,
    required this.note,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: !isSelected ? theme.primary : Colors.red),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(note.title, style: textStyle.bodyMedium)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(note.text, style: textStyle.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }
}
