import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class DraggedNoteImagePayload {
  final int sourceIndex;
  final String imageSource;

  const DraggedNoteImagePayload({
    required this.sourceIndex,
    required this.imageSource,
  });
}

List<quill.EmbedBuilder> buildDraggableNoteImageEmbedBuilders() {
  final builders = FlutterQuillEmbeds.editorBuilders();
  final imageBuilder = builders.firstWhere(
    (builder) => builder.key == quill.BlockEmbed.imageType,
  );

  return [
    DraggableNoteImageEmbedBuilder(delegate: imageBuilder),
    ...builders.where((builder) => builder.key != quill.BlockEmbed.imageType),
  ];
}

class DraggableNoteImageEmbedBuilder extends quill.EmbedBuilder {
  final quill.EmbedBuilder delegate;

  const DraggableNoteImageEmbedBuilder({
    required this.delegate,
  });

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  bool get expanded => delegate.expanded;

  @override
  Widget build(
    BuildContext context,
    quill.EmbedContext embedContext,
  ) {
    final imageWidget = delegate.build(context, embedContext);
    if (embedContext.readOnly) return imageWidget;

    final imageSource = _extractImageSource(embedContext.node.value.data);
    if (imageSource == null || imageSource.isEmpty) return imageWidget;

    return LongPressDraggable<DraggedNoteImagePayload>(
      data: DraggedNoteImagePayload(
        sourceIndex: embedContext.node.documentOffset,
        imageSource: imageSource,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Opacity(opacity: 0.9, child: imageWidget),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: imageWidget,
      ),
      child: imageWidget,
    );
  }

  String? _extractImageSource(dynamic data) {
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      final value = data[quill.BlockEmbed.imageType];
      if (value is String) return value;
    }
    return null;
  }
}
