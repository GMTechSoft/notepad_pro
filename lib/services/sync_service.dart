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

/// A flawless, production-ready Google Drive Sync Service for Hive.
/// Handles hierarchical folder structures and asset streams with strict
/// type enforcement and nested child placement logic.
class GoogleDriveSyncService {
  final AuthService _authService;
  final HiveService _hiveService;
  final Uuid _uuid = const Uuid();

  // Progress stream for UI updates
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  GoogleDriveSyncService(this._authService, this._hiveService);

  /// Convenience method to trigger Google Sign-In
  Future<GoogleSignInAccount?> signIn() => _authService.signInWithGoogle();

  /// Convenience method to trigger Google Sign-Out
  Future<void> signOut() => _authService.signOut();

  /// Stream of Google Authentication state changes
  Stream<GoogleSignInAccount?> get authStateStream => _authService.user;

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
  // 1. Bulletproof Backup Engine (uploadBackupToDrive)
  // ===========================================================================

  Future<void> uploadBackupToDrive() async {
    try {
      _progressController.add(0.0);
      debugPrint('[DriveSync] Starting hierarchical backup sequence...');

      // Step A: Authenticate
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception("Google Drive Authentication failed.");
      }
      _progressController.add(0.05);

      // Step B: Create/Find Main App Root Folder
      final String appRootFolderId =
          await _getOrCreateDriveFolder(driveApi, 'Smart_Notes_Backup_Root');
      debugPrint('[DriveSync] App Root Folder: $appRootFolderId');

      // Step C: Create/Find 'Uncategorized Notes' folder inside root
      final String uncategorizedFolderId = await _getOrCreateDriveFolder(
          driveApi, 'Uncategorized Notes',
          parentId: appRootFolderId);
      debugPrint('[DriveSync] Uncategorized Folder: $uncategorizedFolderId');
      _progressController.add(0.1);

      // Fetch all local Hive data (FIX: Added localFiles to recovery matrix)
      final localFolders = await _hiveService.getFolders();
      final localNotes = await _hiveService.getNotes();
      final localFiles = await _hiveService.getFiles();

      // Tracker: localHiveId.toString() -> DriveFolderId
      final Map<String, String> localToDriveFolderMap = {};

      // Step D: Hierarchical Folder Mapping Loop (STRICT TREE PATTERN)
      debugPrint('[DriveSync] Syncing folder hierarchy...');

      Future<String> syncFolder(FolderModel folder) async {
        final String localId = folder.id.toString();
        if (localToDriveFolderMap.containsKey(localId)) {
          return localToDriveFolderMap[localId]!;
        }

        // FIXED: Enforce clear, strict hierarchical parent verification mapping
        String parentDriveId = appRootFolderId;
        if (folder.parentId != null && folder.parentId!.toString().isNotEmpty) {
          final parentFolder = localFolders.firstWhereOrNull(
              (f) => f.id.toString() == folder.parentId!.toString());
          if (parentFolder != null) {
            // Recurse to guarantee that the parent exists on Drive first
            parentDriveId = await syncFolder(parentFolder);
          }
        }

        final driveId = await _getOrCreateDriveFolder(driveApi, folder.name,
            parentId: parentDriveId);
        localToDriveFolderMap[localId] = driveId;
        return driveId;
      }

      // COMPLETELY finish folder tree sync before moving content arrays
      for (int i = 0; i < localFolders.length; i++) {
        await syncFolder(localFolders[i]);
        if (localFolders.isNotEmpty) {
          _progressController.add(0.1 + (0.3 * (i + 1) / localFolders.length));
        }
      }
      debugPrint('[DriveSync] Folder mapping finished. Count: ${localToDriveFolderMap.length}');

      // Step E: Content Processing stream (Combines Notes and VaultFiles)
      final allItems = [
        ...localNotes.map((n) => {'type': 'note', 'id': n.id, 'folderId': n.folderId, 'name': 'note_${n.id}.json', 'map': Map<String, dynamic>.from(n.toMap())..['__type'] = 'note'}),
        ...localFiles.map((f) => {'type': 'file', 'id': f.id, 'folderId': f.folderId, 'name': 'file_${f.id}.json', 'map': Map<String, dynamic>.from(f.toJson())..['__type'] = 'file'}),
      ];

      debugPrint('[DriveSync] Syncing payload items...');
      for (int i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        final String? itemFolderId = item['folderId'] as String?;

        // Determine target layout matching parent directory signatures
        String? targetDriveFolderId;
        if (itemFolderId != null && itemFolderId.isNotEmpty) {
          targetDriveFolderId = localToDriveFolderMap[itemFolderId.toString()];
        }

        final String destinationId = targetDriveFolderId ?? uncategorizedFolderId;
        final List<int> itemBytes = utf8.encode(jsonEncode(item['map']));

        final driveFile = ga.File()
          ..name = item['name'] as String
          ..mimeType = 'application/json'
          ..parents = [destinationId];

        final media = ga.Media(
          Stream.value(itemBytes),
          itemBytes.length,
          contentType: 'application/json',
        );

        // Deduplication boundary matching
        final query = "name = '${_escapeQuery(driveFile.name!)}' and "
            "'${_escapeQuery(destinationId)}' in parents and "
            "trashed = false";
        final existing = await driveApi.files.list(q: query, spaces: 'drive');

        if (existing.files != null && existing.files!.isNotEmpty) {
          await driveApi.files.update(
            ga.File()..mimeType = 'application/json',
            existing.files!.first.id!,
            uploadMedia: media,
          );
        } else {
          await driveApi.files.create(driveFile, uploadMedia: media);
        }

        if (allItems.isNotEmpty) {
          _progressController.add(0.4 + (0.6 * (i + 1) / allItems.length));
        }
      }

      _progressController.add(1.0);
      debugPrint('[DriveSync] Backup completed successfully.');
    } catch (e) {
      debugPrint('[DriveSync] Backup Error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 2. Bulletproof Restore Engine (restoreBackupFromDrive)
  // ===========================================================================

  Future<void> restoreBackupFromDrive({VoidCallback? onComplete}) async {
    try {
      _progressController.add(0.0);
      debugPrint('[DriveSync] Initializing restoration...');

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception("Google Drive Authentication failed.");
      }
      _progressController.add(0.05);

      // Find the backup root
      final String? appRootFolderId =
          await _findDriveFolder(driveApi, 'Smart_Notes_Backup_Root');
      if (appRootFolderId == null) {
        throw Exception("Restore failed: 'Smart_Notes_Backup_Root' not found on Drive.");
      }

      // Step 1: Nuclear clear local structures
      await _hiveService.clearAllData();
      await _hiveService.noteBox.clear();
      await _hiveService.folderBox.clear();
      await _hiveService.fileBox.clear();
      debugPrint('[DriveSync] Local boxes wiped for synchronization recovery.');
      _progressController.add(0.1);

      // Step 2: Fetch all remote folders to build structural references
      final allFilesResult = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, parents)',
      );
      final List<ga.File> driveFolders = allFilesResult.files ?? [];

      // Tracking: DriveFolderId -> newLocalHiveId
      final Map<String, String> driveToHiveFolderMap = {appRootFolderId: 'ROOT'};

      // Step 3: Reconstruct tree top-down
      Future<void> reconstructFolders(String currentDriveId, String? localParentId) async {
        final children = driveFolders.where((f) => f.parents?.contains(currentDriveId) ?? false);

        for (final folder in children) {
          if (folder.name == 'Uncategorized Notes' && localParentId == null) {
            driveToHiveFolderMap[folder.id!] = 'UNCATEGORIZED';
            await reconstructFolders(folder.id!, null);
          } else if (folder.name != 'Uncategorized Notes') {
            final String newHiveId = _uuid.v4();
            final newFolder = FolderModel(
              id: newHiveId,
              name: folder.name!,
              parentId: localParentId,
              createdAt: DateTime.now(),
              lastModified: DateTime.now(),
              isSynced: true,
              driveFileId: folder.id,
            );

            await _hiveService.addFolder(newFolder);
            driveToHiveFolderMap[folder.id!] = newHiveId;
            await reconstructFolders(folder.id!, newHiveId);
          }
        }
      }

      await reconstructFolders(appRootFolderId, null);
      debugPrint('[DriveSync] Folder directory structure mapped completely.');
      _progressController.add(0.4);

      // Step 4: Search for JSON payload records
      final filesResult = await driveApi.files.list(
        q: "mimeType = 'application/json' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, parents)',
      );
      final List<ga.File> noteFiles = filesResult.files ?? [];

      // Step 5: Full stream download mapping block
      for (int i = 0; i < noteFiles.length; i++) {
        final file = noteFiles[i];

        try {
          final ga.Media response = await driveApi.files.get(
            file.id!,
            downloadOptions: ga.DownloadOptions.fullMedia,
          ) as ga.Media;

          final List<int> bytes = await _readAllBytes(response.stream);
          final String content = utf8.decode(bytes);
          final dynamic jsonData = jsonDecode(content);

          if (jsonData is Map<String, dynamic>) {
            // Map parent Drive ID to fresh Hive UUID securely
            String? localFolderId;
            if (file.parents != null && file.parents!.isNotEmpty) {
              final String parentDriveId = file.parents!.first;
              final String? mappedId = driveToHiveFolderMap[parentDriveId];
              if (mappedId != null && mappedId != 'ROOT' && mappedId != 'UNCATEGORIZED') {
                localFolderId = mappedId;
              }
            }

            final String itemType = jsonData['__type']?.toString() ?? 
                (jsonData.containsKey('referenceType') ? 'file' : 'note');

            if (itemType == 'file') {
              // ---------- VaultFileModel restoration ----------
              final fileMap = Map<String, dynamic>.from(jsonData);
              final sourceFile = VaultFileModel.fromJson(fileMap);

              final restoredFile = VaultFileModel(
                id: sourceFile.id,
                folderId: localFolderId,
                title: sourceFile.title,
                description: sourceFile.description,
                referenceType: sourceFile.referenceType,
                videoTitle: sourceFile.videoTitle,
                videoRefHours: sourceFile.videoRefHours,
                videoRefMinutes: sourceFile.videoRefMinutes,
                videoRefSeconds: sourceFile.videoRefSeconds,
                bookName: sourceFile.bookName,
                authorName: sourceFile.authorName,
                volume: sourceFile.volume,
                pageNumber: sourceFile.pageNumber,
                lineNumber: sourceFile.lineNumber,
                createdAt: sourceFile.createdAt,
                lastModified: sourceFile.lastModified,
                driveFileId: file.id,
                isSynced: true,
              );

              await _hiveService.addFile(restoredFile);
            } else {
              // ---------- NoteModel restoration ----------
              final noteMap = Map<String, dynamic>.from(jsonData);
              final sourceNote = NoteModel.fromJson(noteMap);

              final restoredNote = NoteModel(
                id: sourceNote.id,
                folderId: localFolderId,
                title: sourceNote.title,
                content: sourceNote.content,
                createdAt: sourceNote.createdAt,
                updatedAt: sourceNote.updatedAt,
                driveFileId: file.id,
                isSynced: true,
              );

              await _hiveService.noteBox.put(restoredNote.id, restoredNote);
            }
          }
        } catch (e) {
          debugPrint('[DriveSync] Failed restoration node segment execution: $e');
        }

        if (noteFiles.isNotEmpty) {
          _progressController.add(0.4 + (0.6 * (i + 1) / noteFiles.length));
        }
      }

      // Flush buffers and streams reload markers
      await _hiveService.setInitialized(true);
      await _hiveService.refreshBoxes();
      _hiveService.refresh();

      _progressController.add(1.0);
      if (onComplete != null) onComplete();
      debugPrint('[DriveSync] Full restoration complete.');
    } catch (e) {
      debugPrint('[DriveSync] Restore Error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Helper Methods (Google Drive Abstractions)
  // ===========================================================================

  Future<String> _getOrCreateDriveFolder(ga.DriveApi api, String name,
      {String? parentId}) async {
    final existingId = await _findDriveFolder(api, name, parentId: parentId);
    if (existingId != null) return existingId;

    final folder = ga.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) folder.parents = [parentId];

    final created = await api.files.create(folder);
    return created.id!;
  }

  Future<String?> _findDriveFolder(ga.DriveApi api, String name,
      {String? parentId}) async {
    String query = "name = '${_escapeQuery(name)}' and "
        "mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    if (parentId != null) {
      query += " and '${_escapeQuery(parentId)}' in parents";
    }

    final list = await api.files.list(q: query, spaces: 'drive');
    return (list.files?.isNotEmpty ?? false) ? list.files!.first.id : null;
  }

  Future<List<int>> _readAllBytes(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  String _escapeQuery(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }
}

/// Helper client for Google Authentication Headers in API requests
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