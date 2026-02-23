import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do_app/common/widgets/draggable_note_image_embed_builder.dart';
import 'package:to_do_app/common/widgets/editor_shell.dart';
import 'package:to_do_app/common/widgets/note_color_toolbar.dart';
import 'package:to_do_app/common/utils/note_folder_picker_modal.dart';
import 'package:to_do_app/common/utils/note_rich_text_codec.dart';
import 'package:to_do_app/common/utils/quill_auto_linker.dart';
import 'package:to_do_app/core/notifications/notifications_service.dart';
import 'package:to_do_app/domain/models/folder.dart';
import 'package:to_do_app/domain/models/note.dart';
import 'package:to_do_app/presentation/cubits/folders/folder_cubit.dart';
import 'package:to_do_app/presentation/cubits/notes/note_cubit.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  bool _alreadySaved = false;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final GlobalKey<quill.EditorState> _contentEditorKey;
  late quill.QuillController _titleController;
  late quill.QuillController _contentController;
  late QuillAutoLinker _titleAutoLinker;
  late QuillAutoLinker _contentAutoLinker;

  DateTime? _selectedDateReminder;
  Set<int> _selectedFolderIds = {};
  late final List<quill.EmbedBuilder> _embedBuilders;

  @override
  void initState() {
    super.initState();
    _titleController = quill.QuillController(
      document: NoteRichTextCodec.titleDocumentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentController = quill.QuillController(
      document: NoteRichTextCodec.documentFromNote(widget.note),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleAutoLinker = QuillAutoLinker(_titleController);
    _contentAutoLinker = QuillAutoLinker(_contentController);
    _contentEditorKey = GlobalKey<quill.EditorState>();
    _embedBuilders = buildDraggableNoteImageEmbedBuilders();
    _selectedDateReminder = widget.note.reminder;
    _selectedFolderIds = widget.note.folderIds.toSet();
  }

  Future<void> _showEditOrDeleteDialog() async {
    if (_selectedDateReminder == null) return;

    final formattedDate =
        '${MaterialLocalizations.of(context).formatFullDate(_selectedDateReminder!)}\n${TimeOfDay.fromDateTime(_selectedDateReminder!).format(context)}';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scheduled reminder'),
          content: Text(formattedDate),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                pickDateReminderDate();
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateReminder = null;
                });
                context.pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickDateReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateReminder ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateReminder ?? DateTime.now(),
        ),
        initialEntryMode: TimePickerEntryMode.inputOnly,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateReminder = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
      final source = pickedFile.path;

      _contentController.replaceText(
        index,
        replaceLength,
        quill.BlockEmbed.image(source),
        null,
      );
    } catch (e) {
      debugPrint('Insert image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to insert image: $e')),
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

  Future<void> _updateNote() async {
    final noteCubit = context.read<NoteCubit>();
    final reminderToSave = (_selectedDateReminder != null &&
            _selectedDateReminder!.isAfter(DateTime.now()))
        ? _selectedDateReminder
        : null;
    final title = NoteRichTextCodec.extractPlainText(_titleController.document);
    final updatedNote = widget.note.copyWith(
      title: title,
      titleRichTextDeltaJson: NoteRichTextCodec.encodeDelta(
        _titleController.document,
      ),
      text: NoteRichTextCodec.extractPlainText(_contentController.document),
      richTextDeltaJson:
          NoteRichTextCodec.encodeDelta(_contentController.document),
      reminder: reminderToSave,
      folderIds: _selectedFolderIds.toList(),
    );
    if (widget.note.reminder != null) {
      await NotificationService().cancelNotification(widget.note.id);
    }

    if (reminderToSave != null) {
      await NotificationService().showNotification(
        id: widget.note.id,
        title: updatedNote.title,
        body: updatedNote.text,
        scheduledDate: reminderToSave,
      );
    }

    await noteCubit.updateNote(updatedNote);
  }

  Future<void> _saveAndGoHome() async {
    if (_alreadySaved) return;
    _alreadySaved = true;
    await _updateNote();
    if (!mounted) return;
    context.go('/home');
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
    if (_selectedFolderIds.isEmpty) return 'Inbox';
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
          _alreadySaved = true;
          await _updateNote();
        }
      },
      child: EditorPageScaffold(
        title: 'Edit Note',
        subtitle: 'Update details and keep your notes organized.',
        reminderEnabled: _selectedDateReminder != null,
        reminderEnabledLabel: 'Reminder on',
        reminderDisabledLabel: 'Set reminder',
        onReminderTap: () {
          if (_selectedDateReminder != null) {
            _showEditOrDeleteDialog();
          } else {
            pickDateReminderDate();
          }
        },
        onBackTap: _saveAndGoHome,
        actionLabel: 'Save Note',
        onActionTap: _saveAndGoHome,
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
                              placeholder: 'Continue writing...',
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
