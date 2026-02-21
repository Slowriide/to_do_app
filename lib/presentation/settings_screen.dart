import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:to_do_app/common/widgets/my_drawer.dart';
import 'package:to_do_app/core/config/theme/theme_presets.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _toHexColor(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final raw = hex.startsWith('#') ? hex.substring(1) : hex;
    if (raw.length != 6) return fallback;
    final value = int.tryParse(raw, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  Future<void> _openColorPicker(ThemeState state) async {
    final presetColor = themePresets
        .firstWhere(
          (preset) => preset.id == state.presetId,
          orElse: () => themePresets.first,
        )
        .seedColor;
    var pickedColor = _parseHexColor(state.customColorHex, presetColor);

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick custom accent'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) => pickedColor = color,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.75,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(pickedColor),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (selectedColor == null) return;
    context.read<ThemeCubit>().setCustomColorHex(_toHexColor(selectedColor));
  }

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
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final colors = theme.colorScheme;
          final currentCustomColor = _parseHexColor(
            state.customColorHex,
            colors.primary,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text('Appearance', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mode', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {state.isDarkmode},
                        onSelectionChanged: (selection) {
                          if (selection.first) {
                            context.read<ThemeCubit>().setDarkMode();
                          } else {
                            context.read<ThemeCubit>().setLightMode();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Color Presets', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final preset in themePresets)
                            _PresetSwatch(
                              label: preset.displayName,
                              color: preset.seedColor,
                              selected: state.activeColorSource == ThemeColorSource.preset &&
                                  state.presetId == preset.id,
                              onTap: () {
                                context.read<ThemeCubit>().selectPreset(preset.id);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Custom Accent', style: theme.textTheme.bodyLarge),
                          ),
                          if (state.activeColorSource == ThemeColorSource.custom)
                            Icon(Icons.check_circle, color: colors.primary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: currentCustomColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.tertiary.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.customColorHex ?? 'No custom color selected',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => _openColorPicker(state),
                            icon: const Icon(Icons.palette_outlined),
                            label: const Text('Pick color'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          context.read<ThemeCubit>().clearCustomColor();
                        },
                        icon: const Icon(Icons.layers_outlined, size: 18),
                        label: const Text('Use selected preset'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PresetSwatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.tertiary.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
