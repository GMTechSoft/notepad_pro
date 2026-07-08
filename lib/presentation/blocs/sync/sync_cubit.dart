import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad_pro/services/auth/auth_service.dart';
import 'package:notepad_pro/services/google_drive_sync_service.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final AuthService _authService;
  final GoogleDriveSyncService _syncService;
  final HiveService _hiveService;
  bool _isSyncing = false;
  StreamSubscription<double>? _progressSubscription;

  SyncCubit(this._authService, this._syncService, this._hiveService) : super(const SyncState()) {
    // Listen to auth state changes from SyncService's broadcast stream
    _syncService.authStateStream.listen((user) async {
      if (user != null) {
        DateTime? parsedSyncTime;
        try {
          final configBox = _hiveService.appSettingsBox;
          final lastSyncStr = configBox.get('last_sync_time', defaultValue: '') as String;
          if (lastSyncStr.isNotEmpty) {
            final ms = int.tryParse(lastSyncStr);
            parsedSyncTime = ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : DateTime.tryParse(lastSyncStr);
          }
          
          // Persist session
          await configBox.put('is_logged_in', true);
          await configBox.put('user_email', user.email);
        } catch (e) {
          debugPrint('Sync settings read/write error: $e');
        }
        
        emit(state.copyWith(
          status: SyncStatus.synced,
          userName: user.displayName,
          userEmail: user.email,
          userPhotoUrl: user.photoUrl,
          lastSync: parsedSyncTime,
        ));
      } else {
        emit(const SyncState(status: SyncStatus.signedOut));
      }
      _updateLocalCounts();
    });

    // Listen to progress updates
    _progressSubscription = _syncService.progressStream.listen((progress) {
      emit(state.copyWith(progress: progress));
    });

    // Listen to Hive changes to update total count
    _hiveService.fileBox.listenable().addListener(_updateLocalCounts);
    _hiveService.noteBox.listenable().addListener(_updateLocalCounts);
    _hiveService.folderBox.listenable().addListener(_updateLocalCounts);

    // Persistent Login Check
    initialize();
  }

  void _updateLocalCounts() {
    final totalCount = _hiveService.fileBox.length + 
                       _hiveService.noteBox.length + 
                       _hiveService.folderBox.length;
    
    final syncedFilesCount = _hiveService.fileBox.values.where((e) => e.isSynced).length;
    final syncedNotesCount = _hiveService.noteBox.values.where((e) => e.isSynced).length;
    final syncedFoldersCount = _hiveService.folderBox.values.where((e) => e.isSynced).length;
    final totalSyncedCount = syncedFilesCount + syncedNotesCount + syncedFoldersCount;

    emit(state.copyWith(
      totalFiles: totalCount,
      driveFiles: totalSyncedCount,
    ));
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _hiveService.fileBox.listenable().removeListener(_updateLocalCounts);
    _hiveService.noteBox.listenable().removeListener(_updateLocalCounts);
    _hiveService.folderBox.listenable().removeListener(_updateLocalCounts);
    return super.close();
  }

  Future<void> initialize() async {
    try {
      final configBox = _hiveService.appSettingsBox;
      
      final bool isLoggedIn = configBox.get('is_logged_in', defaultValue: false) as bool;
      final String cachedEmail = configBox.get('user_email', defaultValue: '') as String;
      
      final String lastSyncTimeStr = configBox.get('last_sync_time', defaultValue: '') as String;
      final int cachedCount = configBox.get('cloud_backup_count', defaultValue: 0) as int;
      
      DateTime? parsedSyncTime;
      if (lastSyncTimeStr.isNotEmpty) {
        final int? millis = int.tryParse(lastSyncTimeStr);
        if (millis != null) {
          parsedSyncTime = DateTime.fromMillisecondsSinceEpoch(millis);
        } else {
          parsedSyncTime = DateTime.tryParse(lastSyncTimeStr); // fallback for older ISO formats
        }
      }

      // If previously logged in, emit synced state early with cached email
      if (isLoggedIn) {
        emit(state.copyWith(
          status: SyncStatus.synced,
          userEmail: cachedEmail,
          lastSync: parsedSyncTime,
          driveFiles: cachedCount,
        ));
      } else {
        emit(state.copyWith(
          lastSync: parsedSyncTime,
          driveFiles: cachedCount,
        ));
      }
      
      _updateLocalCounts();

      await _authService.signInSilently();
      // If auto-sync is enabled and user is signed in, trigger a background sync
      if (state.status != SyncStatus.signedOut && state.autoSync) {
        await performAutoSync();
      }
    } catch (e) {
      debugPrint('SyncCubit initialization error: $e');
      emit(state.copyWith(lastSync: null, driveFiles: 0));
    }
  }

  Future<void> signIn() async {
    try {
      final user = await _syncService.signIn();
      if (user != null) {
        await backupNow();
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      final configBox = _hiveService.appSettingsBox;
      await configBox.put('is_logged_in', false);
      await configBox.delete('user_email');
      await _syncService.signOut();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> backupNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    emit(state.copyWith(status: SyncStatus.pending));
    try {
      await _syncService.uploadBackupToDrive();
      
      final now = DateTime.now();
      _updateLocalCounts(); // This recalculates totalSyncedCount
      
      try {
        final configBox = _hiveService.appSettingsBox;
        await configBox.put('last_sync_time', now.millisecondsSinceEpoch.toString());
        await configBox.put('cloud_backup_count', state.driveFiles);
      } catch (e) {
        debugPrint('Sync settings write error: $e');
      }

      emit(state.copyWith(
        status: SyncStatus.synced,
        lastSync: now,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> restoreNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    emit(state.copyWith(status: SyncStatus.pending));
    try {
      await _syncService.restoreBackupFromDrive();
      
      final now = DateTime.now();
      _updateLocalCounts();
      
      try {
        final configBox = _hiveService.appSettingsBox;
        await configBox.put('last_sync_time', now.millisecondsSinceEpoch.toString());
        await configBox.put('cloud_backup_count', state.driveFiles);
      } catch (e) {
        debugPrint('Sync settings write error: $e');
      }

      emit(state.copyWith(
        status: SyncStatus.synced,
        lastSync: now,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> performAutoSync() async {
    if (state.status == SyncStatus.signedOut || !state.autoSync) return;
    await backupNow();
  }

  void syncNow() {
    if (state.status == SyncStatus.signedOut) return;
    backupNow();
  }

  void toggleAutoSync(bool value) {
    emit(state.copyWith(autoSync: value));
  }

  void toggleOfflineSync(bool value) {
    emit(state.copyWith(offlineSync: value));
  }

  void simulatePending() {
    emit(state.copyWith(
      status: SyncStatus.pending,
      totalFiles: 29,
      driveFiles: 24,
    ));
  }
}
