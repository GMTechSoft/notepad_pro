import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/services/export_service.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';
import 'package:notepad_pro/core/utils/text_direction_utils.dart';
import '../../blocs/notes/notes_cubit.dart'; // Corrected import for Cubit

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  NoteEditorScreenState createState() => NoteEditorScreenState();
}

class NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaved = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // In a real app, you'd load the note content here.
    if (widget.noteId != 'new') {
      _titleController.text = 'Sample Note Title';
      _contentController.text = 'This is the content of the sample note.';
    }

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (_isSaved && !_isSaving) {
      setState(() {
        _isSaved = false;
      });
    }
  }

  void _exportCurrentNote() async {
    final note = VaultFile(
      id: widget.noteId,
      title: _titleController.text,
      description: _contentController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ExportService.exportAsTxt(note);
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    try {
      await context.read<NotesCubit>().updateNote(
        widget.noteId,
        _contentController.text,
      );
      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note Saved!', style: TextStyle(color: context.isDark ? Colors.black : Colors.white)),
            duration: const Duration(seconds: 1),
            backgroundColor: context.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.primaryColor),
        title: Text(
          widget.noteId == 'new' ? 'New Note' : 'Edit Note',
          style: TextStyle(
            color: context.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: context.primaryColor),
            onPressed: _exportCurrentNote,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: _isSaving 
                ? SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                    ),
                  )
                : Text(
                    _isSaved ? 'Saved' : 'Unsaved',
                    style: TextStyle(color: context.subText, fontSize: 12),
                  ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.save,
              color: (_isSaved || _isSaving) ? context.border : context.primaryColor,
            ),
            onPressed: (_isSaved || _isSaving) ? null : _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              cursorColor: context.primaryColor,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: context.subText),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.primaryText,
              ),
              textDirection: TextDirectionUtils.getDirection(_titleController.text),
              textAlign: TextDirectionUtils.getTextAlign(_titleController.text),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                cursorColor: context.primaryColor,
                decoration: InputDecoration(
                  hintText: 'Content',
                  hintStyle: TextStyle(color: context.subText),
                  border: InputBorder.none,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  color: context.primaryText,
                  fontSize: 14,
                ),
                textDirection: TextDirectionUtils.getDirection(_contentController.text),
                textAlign: TextDirectionUtils.getTextAlign(_contentController.text),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
