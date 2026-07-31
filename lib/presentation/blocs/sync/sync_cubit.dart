import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/services/auth/auth_service.dart';
import 'package:notepad_pro/services/google_drive_sync_service.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/services/connectivity_service.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final AuthService _authService;
  final GoogleDriveSyncService _syncService;
  final HiveService _hiveService;
  
  bool _isSyncing = false;
  bool _hasSyncError = false;
  bool _isUserSignedIn = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;

  StreamSubscription<double>? _progressSubscription;
  StreamSubscription<ConnectionStatus>? _connectivitySubscription;
  StreamSubscription<BoxEvent>? _fileDeleteSubscription;
  StreamSubscription<BoxEvent>? _noteDeleteSubscription;
  StreamSubscription<BoxEvent>? _folderDeleteSubscription;

  SyncCubit(this._authService, this._syncService, this._hiveService) : super(const SyncState()) {
    // Listen to auth state changes from SyncService's broadcast stream
    _syncService.authStateStream.listen((user) async {
      debugPrint('[SyncCubit] authStateStream: received user update: ${user?.email}');
      _isUserSignedIn = (user != null);
      
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
          debugPrint('[SyncCubit] authStateStream: persisted session for ${user.email}');
        } catch (e) {
          debugPrint('Sync settings read/write error: $e');
        }
        
        emit(state.copyWith(
          userName: user.displayName,
          userEmail: user.email,
          userPhotoUrl: user.photoUrl,
          lastSync: parsedSyncTime,
        ));
        
        // Fetch cloud items count upon sign in
        updateCloudCount();
      } else {
        debugPrint('[SyncCubit] authStateStream: user is null, clearing credentials');
        emit(const SyncState(status: SyncStatus.signedOut));
      }
      _updateLocalCounts();
    });

    // Listen to progress updates
    _progressSubscription = _syncService.progressStream.listen((progress) {
      emit(state.copyWith(progress: progress));
    });

    // Listen to Hive changes to update counts in real-time
    _hiveService.fileBox.listenable().addListener(_updateLocalCounts);
    _hiveService.noteBox.listenable().addListener(_updateLocalCounts);
    _hiveService.folderBox.listenable().addListener(_updateLocalCounts);

    // Subscribe to Connectivity Changes
    final connectivityService = sl<ConnectivityService>();
    _connectivitySubscription = connectivityService.connectionStatusStream.listen(_handleConnectivityChange);
    
    // Check initial connectivity status
    connectivityService.checkInitialConnectivity().then(_handleConnectivityChange);

    // Listen to Hive deletion events to update cloud count
    _fileDeleteSubscription = _hiveService.fileBox.watch().listen((event) {
      if (event.deleted) updateCloudCount();
    });
    _noteDeleteSubscription = _hiveService.noteBox.watch().listen((event) {
      if (event.deleted) updateCloudCount();
    });
    _folderDeleteSubscription = _hiveService.folderBox.watch().listen((event) {
      if (event.deleted) updateCloudCount();
    });

    // Persistent Login Check
    initialize();
  }

  void _handleConnectivityChange(ConnectionStatus connectionStatus) {
    debugPrint('[SyncCubit] Connectivity changed to: $connectionStatus');
    _connectionStatus = connectionStatus;
    _updateSyncStatus();
    
    // Refresh cloud count and auto-sync on reconnect
    if (connectionStatus == ConnectionStatus.online) {
      updateCloudCount();
      final pending = (_hiveService.fileBox.values.where((e) => !e.isSynced).length) +
                      (_hiveService.noteBox.values.where((e) => !e.isSynced).length) +
                      (_hiveService.folderBox.values.where((e) => !e.isSynced).length);
      if (_isUserSignedIn && state.autoSync && state.offlineSync && pending > 0) {
        debugPrint('[SyncCubit] Reconnected to internet, starting auto sync...');
        performAutoSync();
      }
    }
  }

  void _updateSyncStatus() {
    SyncStatus newStatus;
    if (!_isUserSignedIn) {
      newStatus = SyncStatus.signedOut;
    } else if (_connectionStatus == ConnectionStatus.offline) {
      newStatus = SyncStatus.offline;
    } else if (_isSyncing) {
      newStatus = SyncStatus.syncing;
    } else if (_hasSyncError) {
      newStatus = SyncStatus.error;
    } else if (state.pendingFiles > 0) {
      newStatus = SyncStatus.pending;
    } else {
      newStatus = SyncStatus.connected;
    }
    
    emit(state.copyWith(status: newStatus));
  }

  void _updateLocalCounts() {
    final totalCount = _hiveService.fileBox.length + 
                       _hiveService.noteBox.length + 
                       _hiveService.folderBox.length;
    
    final unsyncedFilesCount = _hiveService.fileBox.values.where((e) => !e.isSynced).length;
    final unsyncedNotesCount = _hiveService.noteBox.values.where((e) => !e.isSynced).length;
    final unsyncedFoldersCount = _hiveService.folderBox.values.where((e) => !e.isSynced).length;
    final totalUnsyncedCount = unsyncedFilesCount + unsyncedNotesCount + unsyncedFoldersCount;

    emit(state.copyWith(
      totalFiles: totalCount,
      pendingFiles: totalUnsyncedCount,
    ));

    _updateSyncStatus();
  }

  Future<void> updateCloudCount() async {
    if (!_isUserSignedIn || _connectionStatus == ConnectionStatus.offline) {
      return;
    }
    try {
      final cloudCount = await _syncService.getCloudItemCount();
      emit(state.copyWith(driveFiles: cloudCount));
    } catch (e) {
      debugPrint('[SyncCubit] Error updating cloud count: $e');
      final isNetworkError = e is SocketException || e.toString().contains('SocketException') || e.toString().contains('host lookup') || e.toString().contains('network') || e.toString().contains('Offline') || e.toString().contains('ClientException');
      if (isNetworkError) {
        _connectionStatus = ConnectionStatus.offline;
        _updateSyncStatus();
      }
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _fileDeleteSubscription?.cancel();
    _noteDeleteSubscription?.cancel();
    _folderDeleteSubscription?.cancel();
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
          parsedSyncTime = DateTime.tryParse(lastSyncTimeStr);
        }
      }

      _isUserSignedIn = isLoggedIn;

      if (isLoggedIn) {
        emit(state.copyWith(
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
      if (_isUserSignedIn) {
        await updateCloudCount();
        if (state.autoSync) {
          await performAutoSync();
        }
      }
    } catch (e) {
      debugPrint('SyncCubit initialization error: $e');
      emit(state.copyWith(lastSync: null, driveFiles: 0));
    }
  }

  Future<void> signIn() async {
    debugPrint('[SyncCubit] signIn: triggering _syncService.signIn()');
    try {
      final user = await _syncService.signIn();
      debugPrint('[SyncCubit] signIn: _syncService.signIn() returned user: ${user?.email}');
      if (user != null) {
        _isUserSignedIn = true;
        debugPrint('[SyncCubit] signIn: user is not null, initiating backupNow()');
        await backupNow();
      } else {
        debugPrint('[SyncCubit] signIn: user is null, sign in not completed');
      }
    } catch (e, stack) {
      debugPrint('[SyncCubit] signIn: exception caught: $e');
      debugPrint(stack.toString());
      _hasSyncError = true;
      emit(state.copyWith(errorMessage: e.toString()));
      _updateSyncStatus();
    }
  }

  Future<void> signOut() async {
    try {
      final configBox = _hiveService.appSettingsBox;
      await configBox.put('is_logged_in', false);
      await configBox.delete('user_email');
      _isUserSignedIn = false;
      _hasSyncError = false;
      await _syncService.signOut();
      emit(const SyncState(status: SyncStatus.signedOut));
    } catch (e) {
      _hasSyncError = true;
      emit(state.copyWith(errorMessage: e.toString()));
      _updateSyncStatus();
    }
  }

  Future<void> backupNow() async {
    debugPrint('[SyncCubit] backupNow: checking sync status. _isSyncing = $_isSyncing');
    if (_connectionStatus == ConnectionStatus.offline) {
      emit(state.copyWith(
        status: SyncStatus.offline,
        errorMessage: null,
      ));
      return;
    }
    if (_isSyncing) return;
    _isSyncing = true;
    _hasSyncError = false;
    _updateSyncStatus();
    
    try {
      debugPrint('[SyncCubit] backupNow: calling _syncService.uploadBackupToDrive()');
      await _syncService.uploadBackupToDrive();
      debugPrint('[SyncCubit] backupNow: uploadBackupToDrive finished successfully');
      
      final now = DateTime.now();
      _hasSyncError = false;
      
      // Update local boxes synced state & then update counts
      _updateLocalCounts();
      await updateCloudCount();
      
      try {
        final configBox = _hiveService.appSettingsBox;
        await configBox.put('last_sync_time', now.millisecondsSinceEpoch.toString());
        await configBox.put('cloud_backup_count', state.driveFiles);
      } catch (e) {
        debugPrint('Sync settings write error: $e');
      }

      emit(state.copyWith(
        lastSync: now,
      ));
    } catch (e) {
      final isNetworkError = e is SocketException || e.toString().contains('SocketException') || e.toString().contains('host lookup') || e.toString().contains('network') || e.toString().contains('Offline') || e.toString().contains('ClientException');
      if (isNetworkError) {
        _hasSyncError = false;
        _connectionStatus = ConnectionStatus.offline;
        emit(state.copyWith(
          status: SyncStatus.offline,
          errorMessage: null,
        ));
      } else {
        _hasSyncError = true;
        emit(state.copyWith(
          errorMessage: e.toString(),
        ));
      }
      await updateCloudCount();
    } finally {
      _isSyncing = false;
      _updateSyncStatus();
    }
  }

  Future<void> restoreNow({BuildContext? context}) async {
    if (_connectionStatus == ConnectionStatus.offline) {
      emit(state.copyWith(
        status: SyncStatus.offline,
        errorMessage: null,
      ));
      return;
    }
    if (_isSyncing) return;
    _isSyncing = true;
    _hasSyncError = false;
    _updateSyncStatus();

    try {
      await _syncService.restoreBackupFromDrive();
      await _hiveService.refreshBoxes();

      if (context != null && context.mounted) {
        await context.read<FoldersCubit>().loadFolders();
        if (context.mounted) {
          await context.read<FilesCubit>().loadFiles();
        }
      }
      
      final now = DateTime.now();
      _hasSyncError = false;
      
      _updateLocalCounts();
      await updateCloudCount();
      
      try {
        final configBox = _hiveService.appSettingsBox;
        await configBox.put('last_sync_time', now.millisecondsSinceEpoch.toString());
        await configBox.put('cloud_backup_count', state.driveFiles);
      } catch (e) {
        debugPrint('Sync settings write error: $e');
      }

      emit(state.copyWith(
        lastSync: now,
      ));
    } catch (e) {
      final isNetworkError = e is SocketException || e.toString().contains('SocketException') || e.toString().contains('host lookup') || e.toString().contains('network') || e.toString().contains('Offline') || e.toString().contains('ClientException');
      if (isNetworkError) {
        _hasSyncError = false;
        _connectionStatus = ConnectionStatus.offline;
        emit(state.copyWith(
          status: SyncStatus.offline,
          errorMessage: null,
        ));
      } else {
        _hasSyncError = true;
        emit(state.copyWith(
          errorMessage: e.toString(),
        ));
      }
      await updateCloudCount();
    } finally {
      _isSyncing = false;
      _updateSyncStatus();
    }
  }

  Future<void> performAutoSync() async {
    if (!_isUserSignedIn) return;
    if (_connectionStatus == ConnectionStatus.offline) return;
    
    final pending = (_hiveService.fileBox.values.where((e) => !e.isSynced).length) +
                    (_hiveService.noteBox.values.where((e) => !e.isSynced).length) +
                    (_hiveService.folderBox.values.where((e) => !e.isSynced).length);
                    
    if (state.autoSync && state.offlineSync && pending > 0) {
      await backupNow();
    }
  }

  Future<void> syncNow() async {
    if (!_isUserSignedIn) return;
    await backupNow();
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
      pendingFiles: 5,
    ));
  }
}
