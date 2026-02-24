import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/rendering.dart';
import 'package:scribble/scribble.dart';

class SketchCanvasPage extends StatefulWidget {
  const SketchCanvasPage({super.key});

  @override
  State<SketchCanvasPage> createState() => _SketchCanvasPageState();
}

class _SketchCanvasPageState extends State<SketchCanvasPage> {
  late final ScribbleNotifier _notifier;
  final GlobalKey _exportBoundaryKey = GlobalKey();
  bool _isEyedropperMode = false;

  Color _lastSelectedColor = Colors.black;
  double _strokeWidth = 6.0;

  // Fondo del canvas
  Color _backgroundColor = Colors.white;

  static const _colors = <Color>[
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  // Fondos sugeridos (podés agregar más)
  static const _backgrounds = <Color>[
    Colors.white,
    Color(0xFFF7F7F7),
    Color(0xFFFFF8E1), // crema
    Color(0xFFE3F2FD), // celeste suave
    Color(0xFFE8F5E9), // verde suave
    Color(0xFF121212), // oscuro
  ];

  @override
  void initState() {
    super.initState();
    _notifier = ScribbleNotifier();

    // Set inicial de color y grosor (si tu versión lo soporta)
    _notifier.setColor(_lastSelectedColor);
    _notifier.setStrokeWidth(_strokeWidth);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _saveSketch() async {
    if (_notifier.currentSketch.lines.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw something before saving.')),
      );
      return;
    }

    final boundary = _exportBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export sketch right now.')),
      );
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export sketch as PNG.')),
      );
      return;
    }
    if (!mounted) return;

    final bytes =
        Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes);
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  void _setStroke(double value) {
    setState(() => _strokeWidth = value);
    // Si tu versión no tiene setStrokeWidth, acá es donde cambiaremos la API.
    _notifier.setStrokeWidth(value);
  }

  void _setBackground(Color color) {
    setState(() => _backgroundColor = color);
  }

  Future<void> _pickCustomPaintColor() async {
    var picked = _lastSelectedColor;
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick paint color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picked,
              onColorChanged: (color) => picked = color,
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
              onPressed: () => Navigator.of(context).pop(picked),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _lastSelectedColor = selected;
    });
    _notifier.setColor(selected);
  }

  void _toggleEyedropper() {
    setState(() {
      _isEyedropperMode = !_isEyedropperMode;
    });
  }

  Future<void> _pickColorFromCanvas(TapDownDetails details) async {
    final boundaryContext = _exportBoundaryKey.currentContext;
    if (boundaryContext == null) return;

    final boundary = boundaryContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final box = boundaryContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);

    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) {
      image.dispose();
      return;
    }

    final width = image.width;
    final height = image.height;
    final x = local.dx.round().clamp(0, width - 1);
    final y = local.dy.round().clamp(0, height - 1);
    final offset = (y * width + x) * 4;

    final r = bytes.getUint8(offset);
    final g = bytes.getUint8(offset + 1);
    final b = bytes.getUint8(offset + 2);
    image.dispose();

    final color = Color.fromARGB(0xFF, r, g, b);
    if (!mounted) return;
    setState(() {
      _lastSelectedColor = color;
      _isEyedropperMode = false;
    });
    _notifier.setColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ScribbleState>(
      valueListenable: _notifier,
      builder: (context, state, child) {
        final selectedColor =
            state is Drawing ? Color(state.selectedColor) : _lastSelectedColor;

        if (state is Drawing) _lastSelectedColor = selectedColor;

        final isErasing = state is Erasing;

        // Para que en fondo oscuro se vean los controles:
        final isDarkBg = _backgroundColor.computeLuminance() < 0.35;
        final controlsTextColor = isDarkBg ? Colors.white : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Draw sketch'),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            actions: [
              IconButton(
                tooltip: 'Undo',
                onPressed: _notifier.canUndo ? _notifier.undo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: _notifier.canRedo ? _notifier.redo : null,
                icon: const Icon(Icons.redo_rounded),
              ),
              IconButton(
                tooltip: 'Erase',
                onPressed: isErasing
                    ? () => _notifier.setColor(_lastSelectedColor)
                    : _notifier.setEraser,
                icon: Icon(
                  Icons.auto_fix_normal_rounded,
                  color: isErasing ? scheme.primary : null,
                ),
              ),
              IconButton(
                tooltip: 'Eyedropper',
                onPressed: _toggleEyedropper,
                icon: Icon(
                  Icons.colorize_rounded,
                  color: _isEyedropperMode ? scheme.primary : null,
                ),
              ),
              IconButton(
                tooltip: 'Clear',
                onPressed: _notifier.clear,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
              IconButton(
                tooltip: 'Save sketch',
                onPressed: _saveSketch,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- Barra superior: colores + fondos ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Colores
                    for (final color in _colors)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _ColorDot(
                          color: color,
                          selected:
                              !isErasing && selectedColor.value == color.value,
                          onTap: () {
                            _lastSelectedColor = color;
                            _notifier.setColor(color);
                          },
                        ),
                      ),
                    Tooltip(
                      message: 'Custom color',
                      child: IconButton(
                        onPressed: _pickCustomPaintColor,
                        icon: const Icon(Icons.palette_outlined),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.black12,
                    ),
                    const SizedBox(width: 10),

                    // Fondos
                    for (final bg in _backgrounds)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _BackgroundDot(
                          color: bg,
                          selected: _backgroundColor.value == bg.value,
                          onTap: () => _setBackground(bg),
                        ),
                      ),
                  ],
                ),
              ),

              // --- Slider de grosor ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.brush, color: controlsTextColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 24,
                        value: _strokeWidth,
                        onChanged: _setStroke,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Indicador visual del grosor
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Container(
                        width: _strokeWidth.clamp(2, 18),
                        height: _strokeWidth.clamp(2, 18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isErasing ? scheme.primary : selectedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Canvas ---
              Expanded(
                child: RepaintBoundary(
                  key: _exportBoundaryKey,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: _backgroundColor,
                          child: Scribble(
                            notifier: _notifier,
                            drawPen: true,
                          ),
                        ),
                      ),
                      if (_isEyedropperMode)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: _pickColorFromCanvas,
                            child: Container(
                              color: Colors.transparent,
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Tap canvas to pick color',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: selected ? 34 : 30,
        height: selected ? 34 : 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _BackgroundDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.35;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: selected ? 34 : 30,
        height: selected ? 34 : 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 18,
                color: isDark ? Colors.white : Colors.black87,
              )
            : null,
      ),
    );
  }
}
