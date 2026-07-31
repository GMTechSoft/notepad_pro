import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/data/repositories/vault_repository_interface.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';

// States
abstract class FilesState extends Equatable {
  const FilesState();
  @override
  List<Object> get props => [];
}

class FilesInitial extends FilesState {}
class FilesLoadInProgress extends FilesState {}
class FilesLoadSuccess extends FilesState {
  final List<VaultFile> files;
  const FilesLoadSuccess(this.files);

  FilesLoadSuccess copyWith({
    List<VaultFile>? files,
  }) {
    return FilesLoadSuccess(
      files ?? this.files,
    );
  }

  @override
  List<Object> get props => [files];
}
class FilesLoadFailure extends FilesState {
    final String message;
    const FilesLoadFailure(this.message);
    @override
    List<Object> get props => [message];
}

// Cubit
class FilesCubit extends Cubit<FilesState> {
  final IVaultRepository _vaultRepository;
  final SyncCubit _syncCubit;

  // Store information about the most recent move for undo
  String? _lastMovedItemId;
  String? _lastOldParentId;

  FilesCubit(this._vaultRepository, this._syncCubit) : super(FilesInitial());

  Future<void> loadFiles() async {
    emit(FilesLoadInProgress());
    debugPrint('FilesCubit state after emit: ${state.runtimeType}');
    try {
      final allFiles = await _vaultRepository.getAllFiles();
      debugPrint('Stage 3: FilesCubit loaded ${allFiles.length} files');
      emit(FilesLoadSuccess(allFiles));
    debugPrint('FilesCubit state after emit: ${state.runtimeType} (files count=${allFiles.length})');
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    debugPrint('FilesCubit state after emit: ${state.runtimeType} (error=${e.toString()})');
    }
  }

  Future<void> createFile({
    String? folderId,
    required String title,
    required String description,
    ReferenceType referenceType = ReferenceType.none,
    String? videoTitle,
    int? videoRefHours,
    int? videoRefMinutes,
    int? videoRefSeconds,
    String? bookName,
    String? authorName,
    String? volume,
    int? pageNumber,
    int? lineNumber,
  }) async {
    try {
      await _vaultRepository.createFile(
        folderId: folderId,
        title: title,
        description: description,
        referenceType: referenceType,
        videoTitle: videoTitle,
        videoRefHours: videoRefHours,
        videoRefMinutes: videoRefMinutes,
        videoRefSeconds: videoRefSeconds,
        bookName: bookName,
        authorName: authorName,
        volume: volume,
        pageNumber: pageNumber,
        lineNumber: lineNumber,
      );
      // After creating, re-fetch all files to ensure UI consistency
      await loadFilesForFolder(folderId);
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  Future<void> updateFile(VaultFile file) async {
    try {
      await _vaultRepository.updateFile(file);
      await loadFiles();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  Future<void> deleteFile(String id) async {
    try {
      await _vaultRepository.deleteFile(id);
      await loadFiles();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  // Move any item (file or folder) to a new parent folder
  Future<void> moveItem({required String itemId, required String? targetFolderId}) async {
    try {
      // Record current parent before moving for undo
      final allFiles = await _vaultRepository.getAllFiles();
      // Safely locate the file; if not found, treat as folder move (oldParentId will be null)
      VaultFile? file;
      try {
        file = allFiles.firstWhere((f) => f.id == itemId);
      } catch (_) {
        file = null; // Not a file, likely a folder
      }
      String? oldParentId = file?.folderId;
      // For folders, need to fetch separately (simplified: assume folders are moved via same method)
      // Store move info
      _lastMovedItemId = itemId;
      _lastOldParentId = oldParentId;

      await _vaultRepository.moveItem(itemId: itemId, newParentFolderId: targetFolderId);
      await loadFiles();
      // Trigger sync asynchronously
      Future(() => _syncCubit.performAutoSync());
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  // Undo the most recent move operation
  Future<void> undoLastMove() async {
    if (_lastMovedItemId == null) {
      // Nothing to undo
      return;
    }
    try {
      await _vaultRepository.moveItem(itemId: _lastMovedItemId!, newParentFolderId: _lastOldParentId);
      // Clear undo info after successful undo
      _lastMovedItemId = null;
      _lastOldParentId = null;
      await loadFiles();
      Future(() => _syncCubit.performAutoSync());
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  // Updated moveFileToFolder: instantly updates UI and triggers background sync
  Future<void> moveFileToFolder({required String fileId, required String? targetFolderId}) async {
    try {
      await _vaultRepository.moveFileToFolder(fileId: fileId, targetFolderId: targetFolderId);
      await loadFiles();
      // Trigger sync without awaiting to avoid blocking UI
      Future(() => _syncCubit.performAutoSync());
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

  // Load files for a specific folder (root uses null)
  Future<void> loadFilesForFolder(String? folderId) async {
    emit(FilesLoadInProgress());
    debugPrint('FilesCubit state after emit (folder load): ${state.runtimeType}');
    try {
      final folderFiles = await _vaultRepository.getFiles(folderId);
      debugPrint('FilesCubit loaded folderId=${folderId ?? "ROOT"} files count=${folderFiles.length}');
      emit(FilesLoadSuccess(folderFiles));
    debugPrint('FilesCubit state after emit (folder load): ${state.runtimeType} (files count=${folderFiles.length})');
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
    }
  }

}
