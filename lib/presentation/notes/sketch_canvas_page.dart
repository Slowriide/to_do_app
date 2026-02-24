import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

class SketchCanvasPage extends StatefulWidget {
  const SketchCanvasPage({super.key});

  @override
  State<SketchCanvasPage> createState() => _SketchCanvasPageState();
}

class _SketchCanvasPageState extends State<SketchCanvasPage> {
  late final ScribbleNotifier _notifier;
  Color _lastSelectedColor = Colors.black;

  static const _colors = <Color>[
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _notifier = ScribbleNotifier();
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

    final png = await _notifier.renderImage(pixelRatio: 3);
    if (!mounted) return;
    final bytes =
        Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes);
    Navigator.of(context).pop<Uint8List>(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: _notifier,
      builder: (context, state, child) {
        final selectedColor =
            state is Drawing ? Color(state.selectedColor) : _lastSelectedColor;
        if (state is Drawing) {
          _lastSelectedColor = selectedColor;
        }
        final isErasing = state is Erasing;

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
                  color:
                      isErasing ? Theme.of(context).colorScheme.primary : null,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
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
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.white,
                  child: Scribble(
                    notifier: _notifier,
                    drawPen: true,
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
