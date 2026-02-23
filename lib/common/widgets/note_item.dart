import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:to_do_app/presentation/cubits/note_cubit.dart';
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/domain/models/note.dart';

/// A widget that displays a single note item with its title and text.
///
/// Used to represent a note inside a list or grid. It shows the note's title,
/// text, and an optional pinned icon. If [isSelected] is true, the note's border
/// is highlighted.
///
/// This widget does not handle interaction logic; it is purely presentational.

class NoteItem extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final Widget? dragHandle;

  const NoteItem({
    super.key,
    required this.note,
    required this.isSelected,
    this.dragHandle,
  });

  @override
  State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  static const _titlePreviewMaxHeight = 50.0;
  static const _previewConfig = quill.QuillEditorConfig(
    scrollable: false,
    expands: false,
    showCursor: false,
    enableInteractiveSelection: false,
    padding: EdgeInsets.zero,
  );
  static const _previewMaxHeight = 164.0;
  static final List<quill.EmbedBuilder> _previewEmbedBuilders =
      FlutterQuillEmbeds.editorBuilders();

  late final quill.QuillController _previewController;
  late final quill.QuillController _titlePreviewController;
  late final FocusNode _previewFocusNode;
  late final FocusNode _titlePreviewFocusNode;
  late final ScrollController _previewScrollController;
  late final ScrollController _titlePreviewScrollController;

  @override
  void initState() {
    super.initState();
    _previewController = quill.QuillController(
      document: NoteRichTextCodec.documentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _titlePreviewController = quill.QuillController(
      document: NoteRichTextCodec.titleDocumentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _previewFocusNode = FocusNode(skipTraversal: true, canRequestFocus: false);
    _titlePreviewFocusNode =
        FocusNode(skipTraversal: true, canRequestFocus: false);
    _previewScrollController = ScrollController();
    _titlePreviewScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant NoteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final richChanged =
        oldWidget.note.richTextDeltaJson != widget.note.richTextDeltaJson;
    final textChanged = oldWidget.note.text != widget.note.text;
    if (richChanged || textChanged) {
      _previewController.document = NoteRichTextCodec.documentFromNote(
        widget.note,
      );
    }
    final titleRichChanged = oldWidget.note.titleRichTextDeltaJson !=
        widget.note.titleRichTextDeltaJson;
    final titleChanged = oldWidget.note.title != widget.note.title;
    if (titleRichChanged || titleChanged) {
      _titlePreviewController.document =
          NoteRichTextCodec.titleDocumentFromNote(
        widget.note,
      );
    }
  }

  @override
  void dispose() {
    _previewController.dispose();
    _titlePreviewController.dispose();
    _previewFocusNode.dispose();
    _titlePreviewFocusNode.dispose();
    _previewScrollController.dispose();
    _titlePreviewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    final cardColor = _noteTint(widget.note.id, theme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: widget.isSelected
              ? theme.primary.withValues(alpha: 0.75)
              : theme.tertiary.withValues(alpha: 0.28),
          width: widget.isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: textStyle.bodyLarge ?? const TextStyle(fontSize: 16),
                    child: ClipRect(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _titlePreviewMaxHeight,
                        ),
                        child: IgnorePointer(
                          child: quill.QuillEditor(
                            controller: _titlePreviewController,
                            focusNode: _titlePreviewFocusNode,
                            scrollController: _titlePreviewScrollController,
                            config: _previewConfig.copyWith(
                              embedBuilders: _previewEmbedBuilders,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                widget.note.isPinned
                    ? Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: theme.tertiary,
                      )
                    : const SizedBox.shrink(),
                if (widget.dragHandle != null) ...[
                  const SizedBox(width: 6),
                  widget.dragHandle!,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: DefaultTextStyle.merge(
              style: textStyle.bodyMedium ?? const TextStyle(fontSize: 15),
              child: ClipRect(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: _previewMaxHeight),
                  child: IgnorePointer(
                    child: quill.QuillEditor(
                      controller: _previewController,
                      focusNode: _previewFocusNode,
                      scrollController: _previewScrollController,
                      config: _previewConfig.copyWith(
                        embedBuilders: _previewEmbedBuilders,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _noteTint(int id, ColorScheme theme) {
    const lightTints = <Color>[
      Color(0xFFFFF2AB),
      Color(0xFFD7F4D2),
      Color(0xFFD3ECFF),
      Color(0xFFFFE0C7),
      Color(0xFFE8DCFF),
      Color(0xFFFCD8E6),
    ];
    const darkTints = <Color>[
      Color(0xFF33412A),
      Color(0xFF1F3F3A),
      Color(0xFF213E56),
      Color(0xFF4B3522),
      Color(0xFF3A2F54),
      Color(0xFF4A2738),
    ];
    final isDark = theme.brightness == Brightness.dark;
    final tints = isDark ? darkTints : lightTints;
    return Color.alphaBlend(
      tints[id.abs() % tints.length].withValues(alpha: isDark ? 0.42 : 0.28),
      theme.surface,
    );
  }
}
