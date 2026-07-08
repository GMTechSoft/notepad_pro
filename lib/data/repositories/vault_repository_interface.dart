import '../../domain/entities/folder.dart'; // Import the Folder entity
import '../../domain/entities/vault_file.dart'; // Import the VaultFile entity


abstract class IVaultRepository {
  // Folders
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

  // Files
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
}
