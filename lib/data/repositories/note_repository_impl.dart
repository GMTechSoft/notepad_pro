import 'dart:async';
import 'package:notepad_pro/domain/repositories/note_repository.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class NoteRepositoryImpl implements INoteRepository {
  final HiveService _hiveService;
  final Uuid _uuid = const Uuid();

  NoteRepositoryImpl(this._hiveService);

  @override
  Future<List<NoteModel>> getAllNotes() async {
    return await _hiveService.getNotes();
  }

  @override
  Future<NoteModel?> getNote(String id) async {
    return await _hiveService.getNote(id);
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await _hiveService.updateNote(note.copyWith(isSynced: false));
  }

  @override
  Future<void> deleteNote(String id) async {
    await _hiveService.deleteNote(id);
  }

  @override
  Future<NoteModel> createNote({required String title, required String content, String? folderId}) async {
    final newNote = NoteModel(
      id: _uuid.v4(),
      folderId: folderId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await _hiveService.addNote(newNote);
    return newNote;
  }
}
