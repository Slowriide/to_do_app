import 'package:flutter/material.dart';

class ActivationEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData primaryIcon;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;

  const ActivationEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.primaryIcon = Icons.add_rounded,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return _EmptyStateShell(
      icon: icon,
      secondIcon: Icons.alarm_add_outlined,
      title: title,
      subtitle: subtitle,
      primaryIcon: primaryIcon,
      primaryLabel: primaryLabel,
      onPrimaryTap: onPrimaryTap,
      secondaryLabel: secondaryLabel,
      onSecondaryTap: onSecondaryTap,
    );
  }
}

class NoResultsState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;

  const NoResultsState({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryIcon = Icons.clear_rounded,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return _EmptyStateShell(
      icon: Icons.search_off_rounded,
      secondIcon: Icons.folder_copy_outlined,
      title: title,
      subtitle: subtitle,
      primaryIcon: primaryIcon,
      primaryLabel: primaryLabel,
      onPrimaryTap: onPrimaryTap,
      secondaryLabel: secondaryLabel,
      onSecondaryTap: onSecondaryTap,
    );
  }
}

class _EmptyStateShell extends StatelessWidget {
  final IconData icon;
  final IconData secondIcon;
  final IconData primaryIcon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;

  const _EmptyStateShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
    required this.secondIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.onInverseSurface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colors.tertiary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: colors.onPrimary),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.tertiary),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPrimaryTap,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onSecondaryTap,
                icon: Icon(secondIcon),
                label: Text(secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
