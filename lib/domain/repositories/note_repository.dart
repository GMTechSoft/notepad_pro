import 'package:notepad_pro/data/models/note_model.dart';

abstract class INoteRepository {
  Future<List<NoteModel>> getAllNotes();
  Future<NoteModel?> getNote(String id);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<NoteModel> createNote({required String title, required String content});
}

