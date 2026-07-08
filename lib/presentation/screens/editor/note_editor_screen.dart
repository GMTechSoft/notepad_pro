import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          const SnackBar(content: Text('Note Saved!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
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
      appBar: AppBar(
        title: Text(widget.noteId == 'new' ? 'New Note' : 'Edit Note'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isSaved ? 'Saved' : 'Unsaved'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
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
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
              textDirection: TextDirectionUtils.getDirection(_titleController.text),
              textAlign: TextDirectionUtils.getTextAlign(_titleController.text),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Content',
                  border: InputBorder.none,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
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
