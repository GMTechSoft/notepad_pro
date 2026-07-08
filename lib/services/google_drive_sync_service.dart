import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/services/auth/auth_service.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';

/// A robust, production-ready Google Drive Sync Service for Hive.
/// Implements deep hierarchical folder sync and structural restore mechanisms.
class GoogleDriveSyncService {
  final AuthService _authService;
  final HiveService _hiveService;
  final Uuid _uuid = const Uuid();

  // Progress stream for UI updates
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  GoogleDriveSyncService(this._authService, this._hiveService);

  Stream<GoogleSignInAccount?> get authStateStream => _authService.user;
  Future<GoogleSignInAccount?> signIn() => _authService.signInWithGoogle();
  Future<void> signOut() => _authService.signOut();

  /// Authenticate and initialize the Google Drive API client
  Future<ga.DriveApi?> _getDriveApi() async {
    final GoogleSignInAccount? account = await _authService.signInSilently() ??
        await _authService.signInWithGoogle();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    return ga.DriveApi(authenticateClient);
  }

  // ===========================================================================
  // 1. Recursive Backup Engine
  // ===========================================================================

  Future<void> uploadBackupToDrive() async {
    try {
      _progressController.add(0.0);
      debugPrint('[DriveSync] Starting hierarchical backup...');

      final driveApi = await _getDriveApi();
      if (driveApi == null) throw Exception("Google Drive Authentication failed.");
      _progressController.add(0.05);

      // A. Root Structure Setup
      final String appRootId = await _getOrCreateDriveFolder(driveApi, 'Smart_Notes_Backup_Root');
      final String logicalRootId = appRootId; 
      final String uncategorizedId = await _getOrCreateDriveFolder(driveApi, 'Uncategorized Notes', parentId: appRootId);
      _progressController.add(0.1);

      // B. Fetch Data
      final localFolders = await _hiveService.getFolders();
      final localNotes = await _hiveService.getNotes();
      final localFiles = await _hiveService.getFiles();

      // C. Recursive Folder Mapping
      final Map<String, String> hiveToDriveFolderMap = {};

      Future<String> syncFolder(FolderModel folder) async {
        if (hiveToDriveFolderMap.containsKey(folder.id)) return hiveToDriveFolderMap[folder.id]!;

        String parentDriveId = logicalRootId;

        if (folder.parentId != null && folder.parentId!.isNotEmpty) {
          final parentFolder = localFolders.firstWhereOrNull((f) => f.id == folder.parentId);
          if (parentFolder != null) {
            parentDriveId = await syncFolder(parentFolder);
          }
        }

        final folderJson = jsonEncode(folder.toJson());

        if (folder.driveFileId != null && folder.driveFileId!.isNotEmpty) {
          await _updateDriveFolderParentAndMetadata(driveApi, folder.driveFileId!, folder.name, parentDriveId, folderJson);
          hiveToDriveFolderMap[folder.id] = folder.driveFileId!;
        } else {
          final driveId = await _getOrCreateDriveFolder(driveApi, folder.name, parentId: parentDriveId, description: folderJson);
          hiveToDriveFolderMap[folder.id] = driveId;
          await _hiveService.updateFolder(folder.copyWith(driveFileId: driveId, isSynced: true));
        }
        return hiveToDriveFolderMap[folder.id]!;
      }

      // FIXED: Extra closing brace removed so code flows perfectly inside the method
      for (int i = 0; i < localFolders.length; i++) {
        await syncFolder(localFolders[i]);
        _progressController.add(0.1 + (0.2 * (i + 1) / (localFolders.isEmpty ? 1 : localFolders.length)));
      }
      debugPrint('[DriveSync] Folder hierarchy synced.');

      // D. Content Sync (Notes and Files)
      final allItems = [
        ...localNotes.map((n) => {'type': 'note', 'data': n}),
        ...localFiles.map((f) => {'type': 'file', 'data': f}),
      ];

      for (int i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        final type = item['type'] as String;
        final data = item['data'];

        String? folderId;
        String fileName;
        Map<String, dynamic> jsonMap;

        if (type == 'note') {
          final note = data as NoteModel;
          folderId = note.folderId;
          fileName = 'note_${note.id}.json';
          jsonMap = note.toJson()..['__type'] = 'note';
        } else {
          final file = data as VaultFileModel;
          folderId = file.folderId;
          fileName = 'file_${file.id}.json';
          jsonMap = file.toJson()..['__type'] = 'file';
        }

        final String parentDriveId = (folderId == null || folderId.isEmpty)
            ? uncategorizedId
            : (hiveToDriveFolderMap[folderId] ?? uncategorizedId);

        final String? existingFileId = (type == 'note')
            ? (data as NoteModel).driveFileId
            : (data as VaultFileModel).driveFileId;

        final String driveId = await _moveAndUpdateJsonFile(driveApi, fileName, jsonMap, parentDriveId, existingFileId);

        if (type == 'note') {
          await _hiveService.updateNote((data as NoteModel).copyWith(driveFileId: driveId, isSynced: true));
        } else {
          await _hiveService.updateFile((data as VaultFileModel).copyWith(driveFileId: driveId, isSynced: true));
        }

        _progressController.add(0.3 + (0.7 * (i + 1) / (allItems.isEmpty ? 1 : allItems.length)));
      }

      // Force Cubits state reload after new item insertion/sync to avoid local reference Gray Screen crashes
      sl<FoldersCubit>().loadFolders();
      sl<FilesCubit>().loadFiles();

      _progressController.add(1.0);
      debugPrint('[DriveSync] Backup completed successfully.');
    } catch (e) {
      debugPrint('[DriveSync] Backup Error: $e');
      rethrow;
    }
  }

  Future<String> _moveAndUpdateJsonFile(ga.DriveApi api, String name, Map<String, dynamic> data, String parentId, String? existingFileId) async {
    final List<int> bytes = utf8.encode(jsonEncode(data));
    final media = ga.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');

    if (existingFileId != null && existingFileId.isNotEmpty) {
      try {
        final file = await api.files.get(existingFileId) as ga.File;
        final oldParents = file.parents?.join(',') ?? '';

        await api.files.update(ga.File(), existingFileId, uploadMedia: media);

        if (oldParents != parentId) {
          await api.files.update(ga.File(), existingFileId, addParents: parentId, removeParents: oldParents);
        }

        return existingFileId;
      } catch (e) {
        debugPrint('[DriveSync] Failed to update existing file $existingFileId, falling back: $e');
      }
    }

    return await _uploadJsonFile(api, name, data, parentId);
  }

  Future<String> _uploadJsonFile(ga.DriveApi api, String name, Map<String, dynamic> data, String parentId) async {
    final List<int> bytes = utf8.encode(jsonEncode(data));
    final media = ga.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');

    final driveFile = ga.File()
      ..name = name
      ..mimeType = 'application/json'
      ..parents = [parentId];

    final existingId = await _findDriveFile(api, name, parentId: parentId);
    if (existingId != null) {
      await api.files.update(ga.File(), existingId, uploadMedia: media);
      return existingId;
    }

    final globalExistingId = await _findDriveFile(api, name);
    if (globalExistingId != null) {
      await api.files.update(ga.File(), globalExistingId, uploadMedia: media);
      final existingFile = await api.files.get(globalExistingId) as ga.File;
      final oldParents = existingFile.parents?.join(',') ?? '';
      await api.files.update(ga.File(), globalExistingId, addParents: parentId, removeParents: oldParents);
      return globalExistingId;
    }

    final created = await api.files.create(driveFile, uploadMedia: media);
    return created.id!;
  }

  // ===========================================================================
  // 2. Structural Restore Engine
  // ===========================================================================

  Future<void> restoreBackupFromDrive({VoidCallback? onComplete}) async {
    try {
      _progressController.add(0.0);
      debugPrint('[DriveSync] Starting structural restoration...');

      final driveApi = await _getDriveApi();
      if (driveApi == null) throw Exception("Google Drive Authentication failed.");
      _progressController.add(0.05);

      await _hiveService.clearAllData();
      debugPrint('[DriveSync] Local state wiped.');

      final String? appRootId = await _findDriveFolder(driveApi, 'Smart_Notes_Backup_Root');
      if (appRootId == null) throw Exception("Restore source 'Smart_Notes_Backup_Root' not found on Drive.");

      final allDriveFolders = await _listAllFolders(driveApi);
      
      final Map<String, String?> driveToLocalFolderMap = {appRootId: null};

      Future<void> buildTree(String currentDriveId, String? currentLocalParentId) async {
        final children = allDriveFolders.where((f) => f.parents?.contains(currentDriveId) ?? false).toList();

        for (final driveFolder in children) {
          if (driveFolder.name == 'Uncategorized Notes' && currentLocalParentId == null) {
            driveToLocalFolderMap[driveFolder.id!] = null;
            continue;
          }

          final String localId = _uuid.v4();
          
          FolderModel folder;
          if (driveFolder.description != null && driveFolder.description!.isNotEmpty) {
            try {
              final jsonMap = jsonDecode(driveFolder.description!) as Map<String, dynamic>;
              folder = FolderModel.fromJson(jsonMap).copyWith(
                id: localId,
                parentId: currentLocalParentId,
                driveFileId: driveFolder.id,
                isSynced: true,
              );
            } catch (e) {
              folder = FolderModel(
                id: localId,
                name: driveFolder.name!,
                parentId: currentLocalParentId,
                createdAt: DateTime.now(),
                lastModified: DateTime.now(),
                isSynced: true,
                driveFileId: driveFolder.id,
              );
            }
          } else {
            folder = FolderModel(
              id: localId,
              name: driveFolder.name!,
              parentId: currentLocalParentId,
              createdAt: DateTime.now(),
              lastModified: DateTime.now(),
              isSynced: true,
              driveFileId: driveFolder.id,
            );
          }

          await _hiveService.addFolder(folder);
          driveToLocalFolderMap[driveFolder.id!] = localId;
          
          await buildTree(driveFolder.id!, localId);
        }
      }

      await buildTree(appRootId, null);
      _progressController.add(0.4);

      final allJsonFiles = await _listAllJsonFiles(driveApi);
      
      for (int i = 0; i < allJsonFiles.length; i++) {
        final file = allJsonFiles[i];
        final String? parentDriveId = file.parents?.firstOrNull;
        
        if (parentDriveId != null && driveToLocalFolderMap.containsKey(parentDriveId)) {
          final String? finalFolderId = driveToLocalFolderMap[parentDriveId];

          try {
            final content = await _downloadJson(driveApi, file.id!);
            final type = content['__type'] as String?;

            if (type == 'note') {
              final note = NoteModel.fromJson(content).copyWith(
                folderId: finalFolderId,
                driveFileId: file.id,
                isSynced: true,
              );
              await _hiveService.addNote(note);
            } else if (type == 'file') {
              final vaultFile = VaultFileModel.fromJson(content).copyWith(
                folderId: finalFolderId,
                driveFileId: file.id,
                isSynced: true,
              );
              await _hiveService.addFile(vaultFile);
            }
          } catch (e) {
            debugPrint('[DriveSync] Skipped corrupt file ${file.name}: $e');
          }
        }
        
        _progressController.add(0.4 + (0.6 * (i + 1) / (allJsonFiles.isEmpty ? 1 : allJsonFiles.length)));
      }

      await _hiveService.setInitialized(true);
      await _hiveService.refreshBoxes();

      // Broadcast structural updates after full restoration block
      sl<FoldersCubit>().loadFolders();
      sl<FilesCubit>().loadFiles();

      _progressController.add(1.0);
      if (onComplete != null) onComplete();
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Future<String> _getOrCreateDriveFolder(ga.DriveApi api, String name, {String? parentId, String? description}) async {
    final existingFolder = await _findDriveFolderFull(api, name, parentId: parentId);
    if (existingFolder != null) {
      if (description != null && existingFolder.description != description) {
        final updateFile = ga.File()..description = description;
        await api.files.update(updateFile, existingFolder.id!);
      }
      return existingFolder.id!;
    }

    final globalFolder = await _findDriveFolderFull(api, name);
    if (globalFolder != null && parentId != null) {
      final existingFile = await api.files.get(globalFolder.id!) as ga.File;
      final oldParents = existingFile.parents?.join(',') ?? '';
      await api.files.update(
        ga.File(),
        globalFolder.id!,
        addParents: parentId,
        removeParents: oldParents,
      );
      if (description != null && globalFolder.description != description) {
        await api.files.update(ga.File()..description = description, globalFolder.id!);
      }
      return globalFolder.id!;
    }

    final folder = ga.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) folder.parents = [parentId];
    if (description != null) folder.description = description;

    final created = await api.files.create(folder);
    return created.id!;
  }

  Future<void> _updateDriveFolderParentAndMetadata(ga.DriveApi api, String folderId, String name, String newParentId, String? description) async {
    try {
      final existingFile = await api.files.get(folderId) as ga.File;
      final oldParents = existingFile.parents?.join(',') ?? '';
      await api.files.update(
        ga.File(),
        folderId,
        addParents: newParentId,
        removeParents: oldParents,
      );
      if (description != null) {
        await api.files.update(ga.File()..description = description, folderId);
      }
    } catch (e) {
      final folder = (await _hiveService.getFolders()).firstWhereOrNull((f) => f.driveFileId == folderId);
      if (folder != null) {
        await _hiveService.updateFolder(folder.copyWith(isSynced: false));
      }
      rethrow;
    }
  }

  Future<ga.File?> _findDriveFolderFull(ga.DriveApi api, String name, {String? parentId}) async {
    String query = "name = '${_escapeQuery(name)}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    if (parentId != null) query += " and '${_escapeQuery(parentId)}' in parents";
    final list = await api.files.list(q: query, spaces: 'drive', $fields: 'files(id, description)');
    return list.files?.firstOrNull;
  }

  Future<String?> _findDriveFolder(ga.DriveApi api, String name, {String? parentId}) async {
    String query = "name = '${_escapeQuery(name)}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    if (parentId != null) query += " and '${_escapeQuery(parentId)}' in parents";
    final list = await api.files.list(q: query, spaces: 'drive');
    return list.files?.firstOrNull?.id;
  }

  Future<String?> _findDriveFile(ga.DriveApi api, String name, {String? parentId}) async {
    String query = "name = '${_escapeQuery(name)}' and trashed = false";
    if (parentId != null) query += " and '${_escapeQuery(parentId)}' in parents";
    final list = await api.files.list(q: query, spaces: 'drive');
    return list.files?.firstOrNull?.id;
  }

  Future<List<ga.File>> _listAllFolders(ga.DriveApi api) async {
    final list = await api.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name, parents, description)',
    );
    return list.files ?? [];
  }

  Future<List<ga.File>> _listAllJsonFiles(ga.DriveApi api) async {
    final list = await api.files.list(
      q: "mimeType = 'application/json' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name, parents)',
    );
    return list.files ?? [];
  }

  Future<Map<String, dynamic>> _downloadJson(ga.DriveApi api, String fileId) async {
    final ga.Media media = await api.files.get(fileId, downloadOptions: ga.DownloadOptions.fullMedia) as ga.Media;
    final List<int> bytes = [];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final String content = utf8.decode(bytes);
    return jsonDecode(content) as Map<String, dynamic>;
  }

  String _escapeQuery(String value) => value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}