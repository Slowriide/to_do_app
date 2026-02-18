import 'package:flutter/material.dart';

class EditorPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool reminderEnabled;
  final String reminderEnabledLabel;
  final String reminderDisabledLabel;
  final VoidCallback onReminderTap;
  final VoidCallback onBackTap;
  final Widget child;
  final String actionLabel;
  final VoidCallback onActionTap;
  final IconData actionIcon;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const EditorPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reminderEnabled,
    required this.reminderEnabledLabel,
    required this.reminderDisabledLabel,
    required this.onReminderTap,
    required this.onBackTap,
    required this.child,
    required this.actionLabel,
    required this.onActionTap,
    this.actionIcon = Icons.save_rounded,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: Tooltip(
          message: 'Back',
          child: IconButton(
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ReminderStatusChip(
                          enabled: reminderEnabled,
                          enabledLabel: reminderEnabledLabel,
                          disabledLabel: reminderDisabledLabel,
                          onTap: onReminderTap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: EditorPrimaryActionBar(
        label: actionLabel,
        icon: actionIcon,
        onPressed: onActionTap,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}

class EditorSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const EditorSectionCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.tertiary.withValues(alpha: 0.22),
        ),
      ),
      child: child,
    );
  }
}

class ReminderStatusChip extends StatelessWidget {
  final bool enabled;
  final String enabledLabel;
  final String disabledLabel;
  final VoidCallback onTap;

  const ReminderStatusChip({
    super.key,
    required this.enabled,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: enabled ? 'Edit reminder' : 'Add reminder',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: enabled
                  ? colors.onPrimary.withValues(alpha: 0.16)
                  : colors.onInverseSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? colors.onPrimary.withValues(alpha: 0.5)
                    : colors.tertiary.withValues(alpha: 0.28),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Row(
                key: ValueKey(enabled),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enabled ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
                    size: 18,
                    color: enabled ? colors.onPrimary : colors.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enabled ? enabledLabel : disabledLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditorPrimaryActionBar extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const EditorPrimaryActionBar({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<EditorPrimaryActionBar> createState() => _EditorPrimaryActionBarState();
}

class _EditorPrimaryActionBarState extends State<EditorPrimaryActionBar> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _pressed ? 0.99 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onPrimary.withValues(
                        alpha: enabled ? (_hovered ? 0.22 : 0.14) : 0.0,
                      ),
                      blurRadius: _hovered ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: widget.onPressed,
                  icon: Icon(widget.icon),
                  label: Text(widget.label),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: enabled
                        ? (_hovered
                            ? colors.onPrimary.withValues(alpha: 0.9)
                            : colors.onPrimary)
                        : colors.tertiary.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
