import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/rendering.dart';
import 'package:scribble/scribble.dart';
import 'package:to_do_app/presentation/notes/sketch_crop_page.dart';

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

    final mode = await _pickExportMode();
    if (!mounted || mode == null) return;

    Uint8List? bytes;
    switch (mode) {
      case _SketchExportMode.autoTrim:
        bytes = await _exportAutoTrimmed(boundary);
        break;
      case _SketchExportMode.manualCrop:
        final fullPng = await _exportFullPng(boundary);
        if (!mounted || fullPng == null) return;
        bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => SketchCropPage(imageBytes: fullPng),
          ),
        );
        break;
    }

    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export sketch right now.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  Future<_SketchExportMode?> _pickExportMode() {
    return showModalBottomSheet<_SketchExportMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.auto_fix_high_rounded),
                title: const Text('Auto trim'),
                subtitle:
                    const Text('Detect drawing bounds and remove blank space.'),
                onTap: () =>
                    Navigator.of(context).pop(_SketchExportMode.autoTrim),
              ),
              ListTile(
                leading: const Icon(Icons.crop_rounded),
                title: const Text('Manual crop'),
                subtitle: const Text('Adjust the crop area before saving.'),
                onTap: () =>
                    Navigator.of(context).pop(_SketchExportMode.manualCrop),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> _exportFullPng(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return null;
      return Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List?> _exportAutoTrimmed(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return null;

      final bounds = _findContentBounds(
        rgba: rgba,
        width: image.width,
        height: image.height,
        background: _backgroundColor,
      );
      if (bounds == null) {
        final full = await image.toByteData(format: ui.ImageByteFormat.png);
        if (full == null) return null;
        return Uint8List.view(
          full.buffer,
          full.offsetInBytes,
          full.lengthInBytes,
        );
      }

      final padding = (_strokeWidth * 3).round().clamp(8, 64);
      final paddedBounds = bounds.expand(
        padding: padding,
        maxWidth: image.width,
        maxHeight: image.height,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final src = Rect.fromLTWH(
        paddedBounds.left.toDouble(),
        paddedBounds.top.toDouble(),
        paddedBounds.width.toDouble(),
        paddedBounds.height.toDouble(),
      );
      final dst = Rect.fromLTWH(
        0,
        0,
        paddedBounds.width.toDouble(),
        paddedBounds.height.toDouble(),
      );
      canvas.drawImageRect(image, src, dst, Paint());

      final cropped = await recorder
          .endRecording()
          .toImage(paddedBounds.width, paddedBounds.height);
      try {
        final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) return null;
        return Uint8List.view(
          png.buffer,
          png.offsetInBytes,
          png.lengthInBytes,
        );
      } finally {
        cropped.dispose();
      }
    } finally {
      image.dispose();
    }
  }

  _PixelBounds? _findContentBounds({
    required ByteData rgba,
    required int width,
    required int height,
    required Color background,
  }) {
    const tolerance = 14;
    const alphaThreshold = 16;
    final bgR = (background.r * 255.0).round().clamp(0, 255);
    final bgG = (background.g * 255.0).round().clamp(0, 255);
    final bgB = (background.b * 255.0).round().clamp(0, 255);

    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        final r = rgba.getUint8(offset);
        final g = rgba.getUint8(offset + 1);
        final b = rgba.getUint8(offset + 2);
        final a = rgba.getUint8(offset + 3);
        if (a < alphaThreshold) continue;

        final isBackgroundPixel = (r - bgR).abs() <= tolerance &&
            (g - bgG).abs() <= tolerance &&
            (b - bgB).abs() <= tolerance;
        if (isBackgroundPixel) continue;

        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX < minX || maxY < minY) return null;
    return _PixelBounds(
      left: minX,
      top: minY,
      right: maxX,
      bottom: maxY,
    );
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

    final boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary?;
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
                              !isErasing &&
                              selectedColor.toARGB32() == color.toARGB32(),
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
                          selected:
                              _backgroundColor.toARGB32() == bg.toARGB32(),
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

enum _SketchExportMode { autoTrim, manualCrop }

class _PixelBounds {
  const _PixelBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left + 1;
  int get height => bottom - top + 1;

  _PixelBounds expand({
    required int padding,
    required int maxWidth,
    required int maxHeight,
  }) {
    final newLeft = (left - padding).clamp(0, maxWidth - 1);
    final newTop = (top - padding).clamp(0, maxHeight - 1);
    final newRight = (right + padding).clamp(0, maxWidth - 1);
    final newBottom = (bottom + padding).clamp(0, maxHeight - 1);
    return _PixelBounds(
      left: newLeft,
      top: newTop,
      right: newRight,
      bottom: newBottom,
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
