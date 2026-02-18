import 'package:flutter/material.dart';

Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String itemLabel,
  required int count,
}) async {
  final safeCount = count < 1 ? 1 : count;
  final isPlural = safeCount > 1;
  final noun = isPlural ? '${itemLabel}s' : itemLabel;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: colors.error),
        title: Text('Delete ${isPlural ? '$safeCount $noun' : noun}?'),
        content: Text(
          isPlural
              ? 'You are about to delete $safeCount selected $noun. This action cannot be undone.'
              : 'You are about to delete this $itemLabel. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
