import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/core/storage/note_sketch_storage_service.dart';
import 'package:to_do_app/common/widgets/draggable_note_image_embed_builder.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/common/widgets/note_color_toolbar.dart';
import 'package:to_do_app/common/utils/note_folder_picker_modal.dart';
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/common/utils/quill_auto_linker.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/core/utils/id_generator.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_filter_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';
import 'package:to_do_app/presentation/notes/sketch_canvas_page.dart';

class AddNote extends StatefulWidget {
  final bool autoOpenReminder;

  const AddNote({
    super.key,
    this.autoOpenReminder = false,
  });

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final GlobalKey<quill.EditorState> _contentEditorKey;
  late quill.QuillController _titleController;
  late quill.QuillController _contentController;
  late QuillAutoLinker _titleAutoLinker;
  late QuillAutoLinker _contentAutoLinker;

  DateTime? _reminderDate;
  Set<int> _selectedFolderIds = {};
  late final List<quill.EmbedBuilder> _embedBuilders;
  late final NoteSketchStorageService _sketchStorage;

  @override
  void initState() {
    super.initState();
    _titleController = quill.QuillController(
      document: NoteRichTextCodec.documentFromPlainText(''),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentEditorKey = GlobalKey<quill.EditorState>();
    _embedBuilders = buildDraggableNoteImageEmbedBuilders();
    _contentController = quill.QuillController(
      document: NoteRichTextCodec.documentFromPlainText(''),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _sketchStorage = createNoteSketchStorageService();
    _titleAutoLinker = QuillAutoLinker(_titleController);
    _contentAutoLinker = QuillAutoLinker(_contentController);
    final filter = context.read<FolderFilterCubit>().state;
    final preselectedFolderId =
        filter.type == FolderFilterType.custom ? filter.folderId : null;
    if (preselectedFolderId != null) {
      _selectedFolderIds = {preselectedFolderId};
    }
    if (widget.autoOpenReminder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pickReminderDateTime();
      });
    }
  }

  Future<void> pickReminderDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 6),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _reminderDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _insertImageIntoContent() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (!mounted || pickedFile == null) return;

      final selection = _contentController.selection;
      final baseIndex = selection.isValid
          ? selection.start
          : _contentController.document.length - 1;
      final index = baseIndex.clamp(0, _contentController.document.length - 1);
      final replaceLength =
          selection.isValid ? selection.end - selection.start : 0;
      _insertImageSourceIntoContent(
        source: pickedFile.path,
        index: index,
        replaceLength: replaceLength,
      );
    } catch (e) {
      debugPrint('Insert image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to insert image: $e')),
      );
    }
  }

  void _insertImageSourceIntoContent({
    required String source,
    required int index,
    required int replaceLength,
  }) {
    _contentController.replaceText(
      index,
      replaceLength,
      quill.BlockEmbed.image(source),
      null,
    );
  }

  Future<void> _insertSketchIntoContent() async {
    if (kIsWeb) return;
    try {
      final result = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => const SketchCanvasPage(),
        ),
      );
      if (!mounted || result == null) return;

      final source = await _sketchStorage.savePng(result);
      final selection = _contentController.selection;
      final baseIndex = selection.isValid
          ? selection.start
          : _contentController.document.length - 1;
      final index = baseIndex.clamp(0, _contentController.document.length - 1);
      final replaceLength =
          selection.isValid ? selection.end - selection.start : 0;
      _insertImageSourceIntoContent(
        source: source,
        index: index,
        replaceLength: replaceLength,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save sketch: $e')),
      );
    }
  }

  void _moveDraggedImage({
    required DraggedNoteImagePayload payload,
    required Offset globalDropOffset,
  }) {
    final editorState = _contentEditorKey.currentState;
    if (editorState == null) return;

    final documentLength = _contentController.document.length;
    if (documentLength <= 1) return;

    final dropOffset =
        editorState.renderEditor.getPositionForOffset(globalDropOffset).offset;
    var sourceIndex = payload.sourceIndex.clamp(0, documentLength - 1);
    var destinationIndex = dropOffset.clamp(0, documentLength - 1);
    if (destinationIndex > sourceIndex) {
      destinationIndex -= 1;
    }
    if (destinationIndex == sourceIndex) return;

    _contentController.replaceText(sourceIndex, 1, '', null);
    _contentController.replaceText(
      destinationIndex,
      0,
      quill.BlockEmbed.image(payload.imageSource),
      TextSelection.collapsed(offset: destinationIndex + 1),
    );
  }

  Future<void> _saveNote() async {
    final noteCubit = context.read<NoteCubit>();
    if (_alreadySaved) return;

    _alreadySaved = true;

    if (_formKey.currentState?.validate() ?? false) {
      final title =
          NoteRichTextCodec.extractPlainText(_titleController.document);
      final titleRichTextDeltaJson =
          NoteRichTextCodec.encodeDelta(_titleController.document);
      final text =
          NoteRichTextCodec.extractPlainText(_contentController.document);
      final richTextDeltaJson =
          NoteRichTextCodec.encodeDelta(_contentController.document);
      final uniqueId = IdGenerator.next();

      if (_reminderDate != null) {
        await NotificationService().showNotification(
          id: uniqueId,
          title: title,
          body: text,
          scheduledDate: _reminderDate!,
        );
      }

      if (_reminderDate != null) {
        await noteCubit.addNote(
          text,
          title,
          reminder: _reminderDate,
          id: uniqueId,
          folderIds: _selectedFolderIds.toList(),
          richTextDeltaJson: richTextDeltaJson,
          titleRichTextDeltaJson: titleRichTextDeltaJson,
        );
      } else {
        await noteCubit.addNote(
          text,
          title,
          id: uniqueId,
          folderIds: _selectedFolderIds.toList(),
          richTextDeltaJson: richTextDeltaJson,
          titleRichTextDeltaJson: titleRichTextDeltaJson,
        );
      }

      if (mounted) context.go('/home');
    }
  }

  Future<void> _pickFolder() async {
    final selected = await showNoteFolderPickerModal(
      context: context,
      initialSelection: _selectedFolderIds,
      title: 'Choose folders',
    );

    if (!mounted || selected == null) return;
    if (setEquals(selected, _selectedFolderIds)) return;
    setState(() => _selectedFolderIds = {...selected});
  }

  String _folderLabel(List<Folder> folders) {
    if (_selectedFolderIds.isEmpty) return 'All';
    final selectedNames = folders
        .where((folder) => _selectedFolderIds.contains(folder.id))
        .map((folder) => folder.name)
        .toList();
    if (selectedNames.isEmpty) return 'Folders';
    if (selectedNames.length == 1) return selectedNames.first;
    return '${selectedNames.length} folders';
  }

  @override
  void dispose() {
    _titleAutoLinker.dispose();
    _contentAutoLinker.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_alreadySaved) {
          await _saveNote();
        }
      },
      child: EditorPageScaffold(
        title: 'Create Note',
        subtitle: 'Capture ideas quickly with a clean writing space.',
        reminderEnabled: _reminderDate != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: pickReminderDateTime,
        onBackTap: () => context.pop(),
        actionLabel: 'Save Note',
        onActionTap: _saveNote,
        floatingActionButton: BlocBuilder<FolderCubit, List<Folder>>(
          builder: (context, folders) {
            return FloatingActionButton.extended(
              onPressed: _pickFolder,
              icon: const Icon(Icons.folder_outlined),
              label: Text(_folderLabel(folders)),
              tooltip: 'Select folder',
            );
          },
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditorSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: textStyle.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 70),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.24),
                        ),
                      ),
                      child: quill.QuillEditor.basic(
                        controller: _titleController,
                        config: quill.QuillEditorConfig(
                          placeholder: 'What is this note about?',
                          expands: false,
                          scrollable: false,
                          contextMenuBuilder: (context, rawEditorState) {
                            return NoteSelectionContextMenu(
                              controller: _titleController,
                              rawEditorState: rawEditorState,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EditorSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Content',
                            style:
                                textStyle.titleMedium?.copyWith(fontSize: 18),
                          ),
                        ),
                        Tooltip(
                          message: 'Insert image',
                          child: IconButton(
                            onPressed: _insertImageIntoContent,
                            icon: const Icon(Icons.image_outlined),
                          ),
                        ),
                        if (!kIsWeb)
                          Tooltip(
                            message: 'Draw sketch',
                            child: IconButton(
                              onPressed: _insertSketchIntoContent,
                              icon: const Icon(Icons.draw_outlined),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DragTarget<DraggedNoteImagePayload>(
                      onWillAcceptWithDetails: (_) => true,
                      onAcceptWithDetails: (details) {
                        _moveDraggedImage(
                          payload: details.data,
                          globalDropOffset: details.offset,
                        );
                      },
                      builder: (context, _, __) {
                        return Container(
                          constraints: const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withValues(alpha: 0.24),
                            ),
                          ),
                          child: quill.QuillEditor.basic(
                            controller: _contentController,
                            config: quill.QuillEditorConfig(
                              placeholder: 'Start writing your note...',
                              expands: false,
                              scrollable: false,
                              embedBuilders: _embedBuilders,
                              editorKey: _contentEditorKey,
                              contextMenuBuilder: (context, rawEditorState) {
                                return NoteSelectionContextMenu(
                                  controller: _contentController,
                                  rawEditorState: rawEditorState,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
