import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final allFolders = await _vaultRepository.getAllFolders();
      emit(FoldersLoadSuccess(allFolders));
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

