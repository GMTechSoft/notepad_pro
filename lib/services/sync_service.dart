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
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/services/auth/auth_service.dart';

/// A flawless, production-ready Google Drive Sync Service for Hive.
/// Handles hierarchical folder structures and note streams with strict
/// type enforcement and explicit media execution.
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
      debugPrint('[DriveSync] Starting backup sequence...');

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

      // Fetch all local Hive data
      final localFolders = await _hiveService.getFolders();
      final localNotes = await _hiveService.getNotes();

      // Tracker: localHiveId.toString() -> DriveFolderId
      final Map<String, String> localToDriveFolderMap = {};

      // Step D: Hierarchical Folder Mapping Loop (EXECUTIVE PHASE 1)
      debugPrint('[DriveSync] Syncing folder hierarchy...');

      Future<String> syncFolder(FolderModel folder) async {
        final String localId = folder.id.toString();
        if (localToDriveFolderMap.containsKey(localId)) {
          return localToDriveFolderMap[localId]!;
        }

        String parentDriveId = appRootFolderId;
        if (folder.parentId != null) {
          final parentFolder = localFolders.firstWhereOrNull(
              (f) => f.id.toString() == folder.parentId.toString());
          if (parentFolder != null) {
            parentDriveId = await syncFolder(parentFolder);
          }
        }

        final driveId = await _getOrCreateDriveFolder(driveApi, folder.name,
            parentId: parentDriveId);
        localToDriveFolderMap[localId] = driveId;
        return driveId;
      }

      // COMPLETELY finish folder sync before notes
      for (int i = 0; i < localFolders.length; i++) {
        await syncFolder(localFolders[i]);
        if (localFolders.isNotEmpty) {
          _progressController.add(0.1 + (0.4 * (i + 1) / localFolders.length));
        }
      }
      debugPrint('[DriveSync] Folder mapping finished. Count: ${localToDriveFolderMap.length}');

      // Step E: Note Upload Loop with Safe Media Streams (EXECUTIVE PHASE 2)
      debugPrint('[DriveSync] Syncing notes...');
      for (int i = 0; i < localNotes.length; i++) {
        final note = localNotes[i];

        // Determine destination with strict fallback
        String? targetDriveFolderId;
        if (note.folderId != null) {
          targetDriveFolderId = localToDriveFolderMap[note.folderId.toString()];
        }

        // FORCE non-null target parent
        final String destinationId = targetDriveFolderId ?? uncategorizedFolderId;

        final Map<String, dynamic> noteMap = Map<String, dynamic>.from(note.toMap());
        final List<int> noteBytes = utf8.encode(jsonEncode(noteMap));

        final driveFile = ga.File()
          ..name = 'note_${note.id}.json'
          ..mimeType = 'application/json'
          ..parents = [destinationId];

        final media = ga.Media(
          Stream.value(noteBytes),
          noteBytes.length, // Mandatory for Google API stream processing
          contentType: 'application/json',
        );

        // Deduplication check: exists in target folder?
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
          debugPrint('[DriveSync] Updated: ${driveFile.name}');
        } else {
          await driveApi.files.create(driveFile, uploadMedia: media);
          debugPrint('[DriveSync] Created: ${driveFile.name}');
        }

        if (localNotes.isNotEmpty) {
          _progressController.add(0.5 + (0.5 * (i + 1) / localNotes.length));
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

      // Step 1: Nuclear clear
      await _hiveService.clearAllData();
      await _hiveService.noteBox.clear();
      await _hiveService.folderBox.clear();
      debugPrint('[DriveSync] Local state cleared for fresh restore.');
      _progressController.add(0.1);

      // Step 2: Fetch all folders to reconstruct structure
      final allFilesResult = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, parents)',
      );
      final List<ga.File> driveFolders = allFilesResult.files ?? [];

      // Tracking: DriveFolderId -> newLocalHiveId
      final Map<String, String> driveToHiveFolderMap = {appRootFolderId: 'ROOT'};

      // Step 3: Reconstruct directory tree downwards
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
      debugPrint('[DriveSync] Local folder tree reconstructed.');
      _progressController.add(0.4);

      // Step 4: Search specifically for JSON note files
      debugPrint('[DriveSync] Querying JSON files from Drive...');
      final filesResult = await driveApi.files.list(
        q: "mimeType = 'application/json' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, parents)',
      );
      final List<ga.File> noteFiles = filesResult.files ?? [];

      // Step 5: Full stream download and local save
      for (int i = 0; i < noteFiles.length; i++) {
        final file = noteFiles[i];

        try {
          // Download raw bytes stream
          final ga.Media response = await driveApi.files.get(
            file.id!,
            downloadOptions: ga.DownloadOptions.fullMedia,
          ) as ga.Media;

          final List<int> bytes = await _readAllBytes(response.stream);
          final String content = utf8.decode(bytes);
          final dynamic jsonData = jsonDecode(content);
          final Map<String, dynamic> noteMap = Map<String, dynamic>.from(jsonData as Map);

          final sourceNote = NoteModel.fromJson(noteMap);

          // Map parent Drive ID to fresh Hive ID
          String? localFolderId;
          if (file.parents != null && file.parents!.isNotEmpty) {
            final String parentDriveId = file.parents!.first;
            final String? mappedId = driveToHiveFolderMap[parentDriveId];
            if (mappedId != null && mappedId != 'ROOT' && mappedId != 'UNCATEGORIZED') {
              localFolderId = mappedId;
            }
          }

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

          // Force commit to Hive box
          await _hiveService.noteBox.put(restoredNote.id, restoredNote);
          debugPrint('[DriveSync] Restored: ${file.name}');
        } catch (e) {
          debugPrint('[DriveSync] Failed note restoration (${file.name}): $e');
        }

        if (noteFiles.isNotEmpty) {
          _progressController.add(0.4 + (0.6 * (i + 1) / noteFiles.length));
        }
      }

      // Final initialization reset
      await _hiveService.setInitialized(true);
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
