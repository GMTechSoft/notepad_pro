import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/domain/repositories/note_repository.dart'; // Import INoteRepository
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart'; // Import SyncCubit

part 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final INoteRepository _noteRepository; // Inject NoteRepository
  final SyncCubit _syncCubit; // Inject SyncCubit

  NotesCubit(this._noteRepository, this._syncCubit) : super(NotesInitial());

  Future<void> loadNotes() async {
    emit(NotesLoading());
    try {
      final notes = await _noteRepository.getAllNotes(); // Use repository to get notes
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString())); // Emit error state
    }
  }

  Future<void> createNote(String title, String content) async {
    try {
      await _noteRepository.createNote(title: title, content: content);
      await loadNotes();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> updateNote(String noteId, String newContent) async {
    try {
      // Assuming you have a method to get a single note by ID, modify its content, and then update it
      final existingNote = await _noteRepository.getNote(noteId);
      if (existingNote != null) {
        final updatedNote = existingNote.copyWith(content: newContent);
        await _noteRepository.updateNote(updatedNote); // Use repository to update note
        // After update, re-load notes to reflect changes in UI
        await loadNotes();
        
        // Trigger auto-sync
        _syncCubit.performAutoSync();
      } else {
        emit(NotesError("Note with ID $noteId not found."));
      }
    } catch (e) {
      emit(NotesError(e.toString())); // Emit error state
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _noteRepository.deleteNote(noteId);
      await loadNotes();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }
}

