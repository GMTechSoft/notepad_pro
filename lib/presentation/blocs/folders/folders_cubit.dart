import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/data/repositories/vault_repository_interface.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';


// Cubit
class FoldersCubit extends Cubit<FoldersState> {
  final IVaultRepository _vaultRepository;
  final SyncCubit _syncCubit;

  FoldersCubit(this._vaultRepository, this._syncCubit) : super(FoldersInitial());

  Future<void> loadFolders() async {
    emit(FoldersLoadInProgress());
    debugPrint('FoldersCubit state after emit: ${state.runtimeType}');
    try {
      final allFolders = await _vaultRepository.getAllFolders();
      emit(FoldersLoadSuccess(allFolders));
      debugPrint('FoldersCubit state after emit: ${state.runtimeType} (folders count=${allFolders.length})');
    } catch (e) {
      emit(FoldersLoadFailure(e.toString()));
      debugPrint('FoldersCubit state after emit: ${state.runtimeType} (error=${e.toString()})');
    }
  }

  /// Move a folder to another parent folder (or root if null). Prevent moving a folder into itself or its own descendant.
  Future<void> moveFolder({required String folderId, required String? targetParentId}) async {
    if (folderId == targetParentId) {
      // No operation needed if moving to the same folder
      return;
    }
    // Prevent moving folder into its own descendant
    if (targetParentId != null) {
      final isDesc = await _vaultRepository.isDescendant(folderId: targetParentId, possibleParentId: folderId);
      if (isDesc) {
        emit(FoldersLoadFailure('Cannot move folder into its own descendant'));
        return;
      }
    }
    try {
      await _vaultRepository.moveItem(itemId: folderId, newParentFolderId: targetParentId);
      await loadFolders();
      // Trigger sync without awaiting to keep UI responsive
      Future(() => _syncCubit.performAutoSync());
    } catch (e) {
      emit(FoldersLoadFailure(e.toString()));
    }
  }

  Future<void> createFolder(
    String name,
    String? parentId,
    int? colorValue, {
    int? lightBgColorValue,
    int? darkIconColorValue,
  }) async {
    try {
      await _vaultRepository.createFolder(
        name,
        parentId,
        colorValue,
        lightBgColorValue: lightBgColorValue,
        darkIconColorValue: darkIconColorValue,
      );
      // After creating, re-fetch all folders to ensure UI consistency
      await loadFolders();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FoldersLoadFailure(e.toString()));
    }
  }

  Future<void> updateFolder(Folder folder) async {
    try {
      await _vaultRepository.updateFolder(folder);
      await loadFolders();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FoldersLoadFailure(e.toString()));
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _vaultRepository.deleteFolder(id);
      await loadFolders();
      _syncCubit.performAutoSync();
    } catch (e) {
      emit(FoldersLoadFailure(e.toString()));
    }
  }
}

