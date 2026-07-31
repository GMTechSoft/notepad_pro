import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart' hide ReferenceType;
import 'package:notepad_pro/data/repositories/vault_repository_interface.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/vault_file.dart';
import '../../services/hive_service.dart';
import '../../services/google_drive_sync_service.dart';

class VaultRepositoryImpl implements IVaultRepository {
  final HiveService _hiveService;
  final GoogleDriveSyncService _googleDriveSyncService;
  final Uuid _uuid = const Uuid();

  VaultRepositoryImpl(this._hiveService, this._googleDriveSyncService);

  // ==================== Folders Methods Implementation ====================
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
    final folderModel = FolderModel.fromEntity(folder.copyWith(isSynced: false));
    await _hiveService.updateFolder(folderModel);
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _hiveService.deleteFolder(id);
  }

  // ==================== Files Methods Implementation ====================
  @override
  Future<List<VaultFile>> getFiles(String? folderId) async {
    final fileModels = await _hiveService.getFiles();
    debugPrint('Stage 2: getFiles called with folderId=$folderId, total files in Hive=${fileModels.length}');
    for (var fm in fileModels) {
      debugPrint('FileModel id:${fm.id}, title:${fm.title}, folderId:${fm.folderId}');
    }
    final filtered = fileModels.where((fileModel) {
        if (folderId == null) {
          // Root files: only null as root representation
          return fileModel.folderId == null;
        }
        return fileModel.folderId == folderId;
      }).toList();
    debugPrint('Stage 2: filtered files count=${filtered.length} for folderId=$folderId');
    return filtered.map((fileModel) => fileModel.toEntity()).toList();
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
    final fileModel = VaultFileModel.fromEntity(file.copyWith(isSynced: false));
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

  // ==================== Unified Move & Hierarchy System ====================
  @override
  Future<void> moveFileToFolder({required String fileId, required String? targetFolderId}) async {
    final fileModel = await _hiveService.getFile(fileId);
    if (fileModel == null) return;
    
    final updatedModel = fileModel.copyWith(folderId: targetFolderId, isSynced: false);
    await _hiveService.updateFile(updatedModel);
    
    // Trigger non-blocking cloud backup so location modifications sync right away
    _triggerAsyncCloudSync();
  }

  @override
  Future<void> moveItem({required String itemId, required String? newParentFolderId}) async {
    // 1. Try to process as a folder relocation first
    final folder = await _hiveService.getFolder(itemId);
    if (folder != null) {
      if (newParentFolderId != null) {
        // Use isDescendant to ensure newParentFolderId is not a descendant of the folder being moved
        final isDesc = await isDescendant(folderId: newParentFolderId, possibleParentId: folder.id);
        if (isDesc) {
          throw Exception('Invalid move: target folder is a descendant of the source folder.');
        }
      }
      final updatedFolder = folder.copyWith(parentId: newParentFolderId, isSynced: false);
      await _hiveService.updateFolder(updatedFolder);
      _triggerAsyncCloudSync();
      return;
    }

    // 2. Fallback to processing as a note file layout move
    final file = await _hiveService.getFile(itemId);
    if (file != null) {
      await moveFileToFolder(fileId: itemId, targetFolderId: newParentFolderId);
      return;
    }
    throw Exception('Item with id $itemId not found across storage containers');
  }

  @override
  Future<bool> isDescendant({required String folderId, required String? possibleParentId}) async {
    if (possibleParentId == null) return false;
    String? currentParentId = folderId;
    while (currentParentId != null) {
      if (currentParentId == possibleParentId) {
        return true;
      }
      final folderModel = await _hiveService.getFolder(currentParentId);
      if (folderModel == null) break;
      currentParentId = folderModel.parentId;
    }
    return false;
  }



  @override
  Future<List<VaultFile>> getDirectChildren(String? folderId) async {
    final files = await _hiveService.getFiles();
    final filtered = files.where((f) {
      if (folderId == null) {
        return f.folderId == null;
      }
      return f.folderId == folderId;
    }).map((f) => f.toEntity()).toList();
    return filtered;
  }

  @override
  Future<int> fixOrphanedItems() async {
    final allFolders = await _hiveService.getFolders();
    int fixedCount = 0;
    for (final folder in allFolders) {
      final parentId = folder.parentId;
      if (parentId != null) {
        // Removed undefined appRootId reference; no mapping needed here
        final parent = await _hiveService.getFolder(parentId);
        if (parent == null) {
          final updated = folder.copyWith(parentId: null);
          await _hiveService.updateFolder(updated);
          fixedCount++;
        }
      }
    }
    fixedCount += await fixOrphanedFiles();
    return fixedCount;
  }

  @override
  Future<int> fixOrphanedFiles() async {
    final allFiles = await _hiveService.getFiles();
    int fixedCount = 0;
    for (final file in allFiles) {
      final folderId = file.folderId;
      if (folderId != null) {
        final folder = await _hiveService.getFolder(folderId);
        if (folder == null) {
          final updated = file.copyWith(folderId: null);
          await _hiveService.updateFile(updated);
          fixedCount++;
        }
      }
    }
    return fixedCount;
  }

  @override
  Future<String> getFullPath(String folderId) async {
    List<String> pathTokens = [];
    String? currentId = folderId;
    while (currentId != null) {
      final folder = await _hiveService.getFolder(currentId);
      if (folder == null) break;
      pathTokens.insert(0, folder.name);
      currentId = folder.parentId;
    }
    return pathTokens.join(' / ');
  }

  @override
  Future<List<String>> getRecentFolderIds({int limit = 5}) async {
    final folders = await _hiveService.getFolders();
    final sorted = folders.where((f) => f.parentId != null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).map((f) => f.id).toList();
  }

  // Safe thread non-blocking cloud handler
  void _triggerAsyncCloudSync() async {
    try {
      await _googleDriveSyncService.uploadBackupToDrive();
    } catch (e) {
      debugPrint("Fire-and-forget sync logging caught: ${e.toString()}");
    }
  }
}