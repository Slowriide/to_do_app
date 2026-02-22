import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class NoteColorToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const NoteColorToolbar({
    super.key,
    required this.controller,
  });

  static const List<Color> _palette = [
    Color(0xFFF6C453), // amber
    Color(0xFF7ED9AE), // mint
    Color(0xFF74C7F5), // sky
    Color(0xFFFF9D7E), // coral
    Color(0xFFC4A1FF), // violet
    Color(0xFFFF8FB8), // rose
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectionAttributes = controller.getSelectionStyle().attributes;
        final selectedColorValue = selectionAttributes['color']?.value;
        final boldEnabled =
            selectionAttributes.containsKey(quill.Attribute.bold.key);
        final italicEnabled =
            selectionAttributes.containsKey(quill.Attribute.italic.key);
        final strikeEnabled =
            selectionAttributes.containsKey(quill.Attribute.strikeThrough.key);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: colors.onInverseSurface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FormatToggleButton(
                icon: Icons.format_bold_rounded,
                tooltip: 'Toggle bold',
                selected: boldEnabled,
                onTap: () => _toggleAttribute(
                  quill.Attribute.bold,
                  boldEnabled,
                ),
              ),
              _FormatToggleButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Toggle italic',
                selected: italicEnabled,
                onTap: () => _toggleAttribute(
                  quill.Attribute.italic,
                  italicEnabled,
                ),
              ),
              _FormatToggleButton(
                icon: Icons.format_strikethrough_rounded,
                tooltip: 'Toggle strikethrough',
                selected: strikeEnabled,
                onTap: () => _toggleAttribute(
                  quill.Attribute.strikeThrough,
                  strikeEnabled,
                ),
              ),
              Tooltip(
                message: 'Clear text color',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _clearColor,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Icon(
                      Icons.format_color_reset_rounded,
                      size: 18,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              ..._palette.map(
                (color) {
                  final hex = _toHex(color).toLowerCase();
                  final isSelected =
                      selectedColorValue?.toString().toLowerCase() == hex;
                  return _ColorSwatchButton(
                    color: color,
                    tooltip: 'Apply $hex',
                    selected: isSelected,
                    onTap: () => _applyColor(hex),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyColor(String hex) {
    controller.formatSelection(quill.Attribute.fromKeyValue('color', hex));
  }

  void _clearColor() {
    controller.formatSelection(quill.Attribute.fromKeyValue('color', null));
  }

  void _toggleAttribute(quill.Attribute attribute, bool isEnabled) {
    if (isEnabled) {
      controller.formatSelection(
        quill.Attribute.fromKeyValue(attribute.key, null),
      );
      return;
    }
    controller.formatSelection(attribute);
  }

  String _toHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}

class _FormatToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _FormatToggleButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.82)
                : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.85)
                  : colors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? colors.onPrimaryContainer : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? colors.onSurface : colors.surface,
              width: selected ? 2.3 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: selected ? 5 : 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
