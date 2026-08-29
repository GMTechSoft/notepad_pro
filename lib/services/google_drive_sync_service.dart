import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import 'package:notepad_pro/services/connectivity_service.dart';
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

  Future<ga.DriveApi?> _getDriveApi() async {
    final connectivity = sl<ConnectivityService>();
    final status = await connectivity.checkInitialConnectivity();
    if (status == ConnectionStatus.offline) {
      throw const SocketException('No internet connection');
    }

    debugPrint('[DriveSync] _getDriveApi: checking currentUser');
    GoogleSignInAccount? account = _authService.currentUser;
    if (account != null) {
      debugPrint('[DriveSync] _getDriveApi: currentUser is already not null (${account.email}), validating token and scopes');
      final bool isValid = await _authService.validateCurrentUser(account);
      if (isValid) {
        debugPrint('[DriveSync] _getDriveApi: currentUser is valid, continuing');
      } else {
        debugPrint('[DriveSync] _getDriveApi: currentUser is invalid or lacks scopes, resetting account to null');
        account = null;
      }
    }

    if (account == null) {
      debugPrint('[DriveSync] _getDriveApi: trying silent sign-in');
      account = await _authService.signInSilently();
      if (account != null) {
        debugPrint('[DriveSync] _getDriveApi: silent sign-in succeeded (${account.email})');
      }
    }

    if (account == null) {
      debugPrint('[DriveSync] _getDriveApi: silent sign-in returned null, trying full sign-in');
      account = await _authService.signInWithGoogle();
      if (account != null) {
        debugPrint('[DriveSync] _getDriveApi: full sign-in succeeded (${account.email})');
      } else {
        debugPrint('[DriveSync] _getDriveApi: full sign-in returned null');
      }
    }

    if (account == null) {
      debugPrint('[DriveSync] _getDriveApi: all authentication attempts failed, returning null');
      return null;
    }

    debugPrint('[DriveSync] _getDriveApi: fetching auth headers');
    final authHeaders = await account.authHeaders;
    debugPrint('[DriveSync] _getDriveApi: auth headers fetched successfully');
    final authenticateClient = GoogleAuthClient(authHeaders);
    return ga.DriveApi(authenticateClient);
  }

  // ===========================================================================
  // Cloud Deletion
  // ===========================================================================

  Future<void> deleteFileFromCloud({
    required String cloudFileId,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return;

      await driveApi.files.delete(cloudFileId);
      
      final pending = List<String>.from(_hiveService.appSettingsBox.get('pending_cloud_deletions', defaultValue: []) ?? []);
      pending.remove(cloudFileId);
      await _hiveService.appSettingsBox.put('pending_cloud_deletions', pending);
    } catch (e) {
      debugPrint('[DriveSync] Fast delete failed for $cloudFileId: $e');
      if (e.toString().contains('404')) {
        final pending = List<String>.from(_hiveService.appSettingsBox.get('pending_cloud_deletions', defaultValue: []) ?? []);
        pending.remove(cloudFileId);
        await _hiveService.appSettingsBox.put('pending_cloud_deletions', pending);
      } else {
        rethrow;
      }
    }
  }

  Future<void> processPendingCloudDeletions() async {
    try {
      final pending = List<String>.from(_hiveService.appSettingsBox.get('pending_cloud_deletions', defaultValue: []) ?? []);
      if (pending.isEmpty) return;

      final driveApi = await _getDriveApi();
      if (driveApi == null) return;

      List<String> successfullyDeleted = [];

      for (final cloudFileId in pending) {
        try {
          await driveApi.files.delete(cloudFileId);
          successfullyDeleted.add(cloudFileId);
        } catch (e) {
          debugPrint('[DriveSync] Pending delete failed for $cloudFileId: $e');
          if (e.toString().contains('404')) {
            successfullyDeleted.add(cloudFileId);
          }
        }
      }

      pending.removeWhere((item) => successfullyDeleted.contains(item));
      await _hiveService.appSettingsBox.put('pending_cloud_deletions', pending);
    } catch (e) {
      debugPrint('[DriveSync] processPendingCloudDeletions error: $e');
    }
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
          final noteId = (data as NoteModel).id;
          final latestNote = _hiveService.noteBox.get(noteId);
          if (latestNote != null) {
            await _hiveService.updateNote(latestNote.copyWith(driveFileId: driveId, isSynced: true));
          }
        } else {
          final fileId = (data as VaultFileModel).id;
          final latestFile = _hiveService.fileBox.get(fileId);
          if (latestFile != null) {
            await _hiveService.updateFile(latestFile.copyWith(driveFileId: driveId, isSynced: true));
          }
        }

        _progressController.add(0.3 + (0.7 * (i + 1) / (allItems.isEmpty ? 1 : allItems.length)));
      }

      // Force Cubits state reload after new item insertion/sync to avoid local reference Gray Screen crashes
      sl<FoldersCubit>().loadFolders();
      sl<FilesCubit>().loadFiles();

      await processPendingCloudDeletions();

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

  Future<int> getCloudItemCount() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return 0;
    try {
      final String? appRootId = await _findDriveFolder(driveApi, 'Smart_Notes_Backup_Root');
      if (appRootId == null) {
        debugPrint('Local items: 0');
        debugPrint('Cloud items: 0');
        debugPrint('Cloud item names:');
        debugPrint('Final driveFiles count: 0');
        return 0;
      }

      final allFolders = await _listAllFolders(driveApi);
      final allFiles = await _listAllJsonFiles(driveApi);

      // Find Uncategorized Notes folder (direct child of appRootId)
      String? uncategorizedId;
      for (final folder in allFolders) {
        if (folder.parents?.contains(appRootId) == true && folder.name == 'Uncategorized Notes') {
          uncategorizedId = folder.id;
          break;
        }
      }

      final Set<String> userFolderIds = {};
      final Set<String> structuralFolderIds = {appRootId};
      if (uncategorizedId != null) {
        structuralFolderIds.add(uncategorizedId);
      }

      // Recursively identify user folders
      bool changed = true;
      while (changed) {
        changed = false;
        for (final folder in allFolders) {
          final folderId = folder.id;
          if (folderId == null) continue;
          if (userFolderIds.contains(folderId) || structuralFolderIds.contains(folderId)) {
            continue;
          }

          final hasValidParent = folder.parents?.any((parentId) =>
            parentId == appRootId && folderId != uncategorizedId ||
            userFolderIds.contains(parentId)
          ) ?? false;

          if (hasValidParent) {
            userFolderIds.add(folderId);
            changed = true;
          }
        }
      }

      // Identify user files (MIME type is application/json and parent is uncategorizedId or a user folder)
      final List<ga.File> userFiles = [];
      for (final file in allFiles) {
        final parentId = file.parents?.firstOrNull;
        if (parentId == null) continue;
        if (parentId == uncategorizedId || userFolderIds.contains(parentId)) {
          userFiles.add(file);
        }
      }

      final totalLocalCount = _hiveService.fileBox.length + 
                             _hiveService.noteBox.length + 
                             _hiveService.folderBox.length;

      final finalCount = userFolderIds.length + userFiles.length;

      // Debug Logs (Requirement 7)
      debugPrint('Local items: $totalLocalCount');
      debugPrint('Cloud items: $finalCount');
      final List<String> itemNames = [];
      for (final folderId in userFolderIds) {
        final folder = allFolders.firstWhereOrNull((f) => f.id == folderId);
        if (folder != null) {
          itemNames.add('Folder: ${folder.name} (${folder.id})');
        }
      }
      for (final file in userFiles) {
        itemNames.add('File: ${file.name} (${file.id})');
      }
      debugPrint('Cloud item names:\n${itemNames.join('\n')}');
      debugPrint('Final driveFiles count: $finalCount');

      return finalCount;
    } catch (e) {
      debugPrint('[DriveSync] Error getting cloud item count: $e');
      return 0;
    }
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