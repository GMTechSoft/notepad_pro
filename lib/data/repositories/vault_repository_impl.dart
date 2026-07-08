import 'dart:async';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart' hide ReferenceType;
import 'package:notepad_pro/data/repositories/vault_repository_interface.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/vault_file.dart';
import '../../services/hive_service.dart';

class VaultRepositoryImpl implements IVaultRepository {
  final HiveService _hiveService;
  final Uuid _uuid = const Uuid();

  VaultRepositoryImpl(this._hiveService);

  // Folders
  @override
  Future<List<Folder>> getFolders(String? parentId) async {
    final folderModels = await _hiveService.getFolders();
    return folderModels
        .where((folderModel) => folderModel.parentId == parentId)
        .map((folderModel) => folderModel.toEntity())
        .toList();
  }

  @override
  Future<Folder?> getFolder(String id) async {
    final folderModel = await _hiveService.getFolder(id);
    return folderModel?.toEntity();
  }

  @override
  Future<Folder> createFolder(
    String name, 
    String? parentId, 
    int? colorValue, {
    int? lightBgColorValue, 
    int? darkIconColorValue
  }) async {
    final newFolderEntity = Folder(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorValue: colorValue,
      lightBgColorValue: lightBgColorValue,
      darkIconColorValue: darkIconColorValue,
    );
    final newFolderModel = FolderModel.fromEntity(newFolderEntity);
    await _hiveService.addFolder(newFolderModel);
    
    return newFolderEntity;
  }

  @override
  Future<List<Folder>> getAllFolders() async {
    final folderModels = await _hiveService.getFolders();
    return folderModels
        .map((folderModel) => folderModel.toEntity())
        .toList();
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final folderModel = FolderModel.fromEntity(folder);
    await _hiveService.updateFolder(folderModel);
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _hiveService.deleteFolder(id);
  }

  // Files
  @override
  Future<List<VaultFile>> getFiles(String? folderId) async {
    final fileModels = await _hiveService.getFiles();
    return fileModels
        .where((fileModel) => fileModel.folderId == folderId)
        .map((fileModel) => fileModel.toEntity())
        .toList();
  }

  @override
  Future<VaultFile> createFile({
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
    final newFileEntity = VaultFile(
      id: _uuid.v4(),
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final newFileModel = VaultFileModel.fromEntity(newFileEntity);
    await _hiveService.addFile(newFileModel);
    
    return newFileEntity;
  }

  @override
  Future<void> updateFile(VaultFile file) async {
    final fileModel = VaultFileModel.fromEntity(file);
    await _hiveService.updateFile(fileModel);
  }

  @override
  Future<void> deleteFile(String id) async {
    await _hiveService.deleteFile(id);
  }

  @override
  Future<List<VaultFile>> getAllFiles() async {
    final fileModels = await _hiveService.getFiles();
    return fileModels
        .map((fileModel) => fileModel.toEntity())
        .toList();
  }
}

