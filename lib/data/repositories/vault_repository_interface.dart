import '../../domain/entities/folder.dart'; 
import '../../domain/entities/vault_file.dart'; 

abstract class IVaultRepository {
  // Folders operations contract context
  Future<List<Folder>> getFolders(String? parentId);
  Future<Folder?> getFolder(String id);
  Future<Folder> createFolder(
    String name,
    String? parentId,
    int? colorValue, {
    int? lightBgColorValue,
    int? darkIconColorValue,
  });
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(String id);
  Future<List<Folder>> getAllFolders();

  // Files operations contract context
  Future<VaultFile> createFile({
    String? folderId,
    required String title,
    required String description,
    ReferenceType referenceType,
    String? videoTitle,
    int? videoRefHours,
    int? videoRefMinutes,
    int? videoRefSeconds,
    String? bookName,
    String? authorName,
    String? volume,
    int? pageNumber,
    int? lineNumber,
  });
  Future<void> updateFile(VaultFile file);
  Future<void> deleteFile(String id);
  Future<List<VaultFile>> getFiles(String? folderId);
  Future<List<VaultFile>> getAllFiles();
  
  // Unified Non-Redundant Move & Hierarchy Validation Engine API Contracts
  Future<void> moveFileToFolder({required String fileId, required String? targetFolderId});
  Future<void> moveItem({required String itemId, required String? newParentFolderId});
  Future<bool> isDescendant({required String folderId, required String? possibleParentId});
  Future<List<VaultFile>> getDirectChildren(String? folderId);
  Future<int> fixOrphanedItems();
  Future<int> fixOrphanedFiles();
  Future<String> getFullPath(String folderId);
  Future<List<String>> getRecentFolderIds({int limit = 5});
}