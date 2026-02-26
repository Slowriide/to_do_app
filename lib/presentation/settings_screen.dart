import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:to_do_app/common/widgets/my_drawer.dart';
import 'package:to_do_app/core/backup/backup_service.dart';
import 'package:to_do_app/core/config/theme/theme_presets.dart';
import 'package:to_do_app/data/repository/isar_note_repository_impl.dart';
import 'package:to_do_app/domain/repository/note_repository.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:to_do_app/presentation/cubits/todos/todo_cubit.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  BackupService? _resolveBackupService() {
    final noteRepository = context.read<NoteRepository>();
    if (noteRepository is IsarNoteRepositoryImpl) {
      return createBackupService(noteRepository.db);
    }
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ImportMode?> _showImportModeDialog() {
    return showDialog<ImportMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import backup'),
          content: const Text('Choose how the backup should be imported.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(ImportMode.merge),
              child: const Text('Merge'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(ImportMode.replace),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup() async {
    final backupService = _resolveBackupService();
    if (backupService == null) {
      _showSnack('Backup is not available on this platform.');
      return;
    }

    try {
      _showSnack('Exporting backup...');
      final zipFile = await backupService.exportBackup(includeMedia: true);
      if (!mounted) return;
      await shareBackupZip(zipFile);
      _showSnack('Backup exported: ${zipFile.path}');
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  Future<void> _importBackup() async {
    final backupService = _resolveBackupService();
    final folderCubit = context.read<FolderCubit>();
    final noteCubit = context.read<NoteCubit>();
    final todoCubit = context.read<TodoCubit>();
    if (backupService == null) {
      _showSnack('Backup is not available on this platform.');
      return;
    }

    final pickedFile = await pickBackupZip();
    if (pickedFile == null) return;

    final mode = await _showImportModeDialog();
    if (mode == null) return;

    try {
      _showSnack('Importing backup...');
      await backupService.importBackup(pickedFile, mode: mode);
      if (!mounted) return;
      await folderCubit.loadFolders();
      await noteCubit.loadNotes();
      await todoCubit.loadTodos();
      _showSnack('Backup import completed.');
    } catch (e) {
      _showSnack('Import failed: $e');
    }
  }

  String _toHexColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
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

  Future<Color?> _openColorPickerDialog({
    required String title,
    required Color initialColor,
  }) async {
    var pickedColor = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
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
  }

  Future<void> _openAccentColorPicker(ThemeState state) async {
    final presetColor = themePresets
        .firstWhere(
          (preset) => preset.id == state.presetId,
          orElse: () => themePresets.first,
        )
        .seedColor;
    final selectedColor = await _openColorPickerDialog(
      title: 'Pick custom accent',
      initialColor: _parseHexColor(state.customColorHex, presetColor),
    );

    if (!mounted || selectedColor == null) return;
    context.read<ThemeCubit>().setCustomColorHex(_toHexColor(selectedColor));
  }

  Future<void> _openBackgroundColorPicker(ThemeState state) async {
    final presetBackground = backgroundPresets
        .firstWhere(
          (preset) => preset.id == state.backgroundPresetId,
          orElse: () => backgroundPresets.first,
        )
        .color;
    final selectedColor = await _openColorPickerDialog(
      title: 'Pick custom background',
      initialColor: _parseHexColor(state.customBackgroundHex, presetBackground),
    );

    if (!mounted || selectedColor == null) return;
    context
        .read<ThemeCubit>()
        .setCustomBackgroundHex(_toHexColor(selectedColor));
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
          final currentCustomBackground = _parseHexColor(
            state.customBackgroundHex,
            backgroundPresets
                .firstWhere(
                  (preset) => preset.id == state.backgroundPresetId,
                  orElse: () => backgroundPresets.first,
                )
                .color,
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
                              selected: state.activeColorSource ==
                                      ThemeColorSource.preset &&
                                  state.presetId == preset.id,
                              onTap: () {
                                context
                                    .read<ThemeCubit>()
                                    .selectPreset(preset.id);
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
                            child: Text('Custom Accent',
                                style: theme.textTheme.bodyLarge),
                          ),
                          if (state.activeColorSource ==
                              ThemeColorSource.custom)
                            Icon(Icons.check_circle,
                                color: colors.primary, size: 18),
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
                              state.customColorHex ??
                                  'No custom color selected',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => _openAccentColorPicker(state),
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
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Presets',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final preset in backgroundPresets)
                            _ColorDotOption(
                              label: preset.displayName,
                              color: preset.color,
                              selected: state.activeBackgroundSource ==
                                      ThemeBackgroundSource.preset &&
                                  state.backgroundPresetId == preset.id,
                              onTap: () {
                                context
                                    .read<ThemeCubit>()
                                    .selectBackgroundPreset(preset.id);
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
                            child: Text(
                              'Custom Background',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          if (state.activeBackgroundSource ==
                              ThemeBackgroundSource.custom)
                            Icon(
                              Icons.check_circle,
                              color: colors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: currentCustomBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.tertiary.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.customBackgroundHex ??
                                  'No custom background selected',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => _openBackgroundColorPicker(state),
                            icon: const Icon(Icons.format_paint_outlined),
                            label: const Text('Pick color'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          context.read<ThemeCubit>().clearCustomBackground();
                        },
                        icon: const Icon(Icons.layers_outlined, size: 18),
                        label: const Text('Use selected preset'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Backup & Restore', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Export notes, folders, todos and owned sketch media into a ZIP backup. '
                        'Import can merge or replace existing data.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _exportBackup,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Export backup'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Import backup'),
                            ),
                          ),
                        ],
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

class _ColorDotOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDotOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.tertiary.withValues(alpha: 0.36),
                width: selected ? 2.4 : 1.2,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
        ),
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
              color: selected
                  ? scheme.primary
                  : scheme.tertiary.withValues(alpha: 0.3),
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
