import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SketchCropPage extends StatefulWidget {
  const SketchCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<SketchCropPage> createState() => _SketchCropPageState();
}

class _SketchCropPageState extends State<SketchCropPage> {
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  Size? _imageSize;
  Size? _lastViewport;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _decodeImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    if (!mounted) return;
    setState(() => _imageSize = size);
  }

  Matrix4 _computeInitialTransform({
    required Size viewport,
    required Size source,
  }) {
    final scale = math.max(
      viewport.width / source.width,
      viewport.height / source.height,
    );
    final scaledW = source.width * scale;
    final scaledH = source.height * scale;
    final dx = (viewport.width - scaledW) / 2;
    final dy = (viewport.height - scaledH) / 2;
    return Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);
  }

  Future<void> _finishCrop() async {
    if (_isSaving) return;
    final boundary = _cropBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    setState(() => _isSaving = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted || png == null) return;

      final bytes = Uint8List.view(
        png.buffer,
        png.offsetInBytes,
        png.lengthInBytes,
      );
      Navigator.of(context).pop<Uint8List>(bytes);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual sketch crop'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: imageSize == null || _isSaving ? null : _finishCrop,
            tooltip: 'Use crop',
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                if (_lastViewport != viewport) {
                  _lastViewport = viewport;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _transformController.value = _computeInitialTransform(
                      viewport: viewport,
                      source: imageSize,
                    );
                  });
                }

                return RepaintBoundary(
                  key: _cropBoundaryKey,
                  child: ColoredBox(
                    color: Colors.white,
                    child: ClipRect(
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 0.1,
                        maxScale: 8,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        constrained: false,
                        child: SizedBox(
                          width: imageSize.width,
                          height: imageSize.height,
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
