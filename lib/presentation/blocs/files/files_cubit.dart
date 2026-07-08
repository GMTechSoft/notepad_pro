import 'package:equatable/equatable.dart';
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

  FilesCubit(this._vaultRepository, this._syncCubit) : super(FilesInitial());

  Future<void> loadFiles() async {
    emit(FilesLoadInProgress());
    try {
      final allFiles = await _vaultRepository.getAllFiles();
      emit(FilesLoadSuccess(allFiles));
    } catch (e) {
      emit(FilesLoadFailure(e.toString()));
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
      await loadFiles();
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
}

