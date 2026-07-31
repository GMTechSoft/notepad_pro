import 'package:equatable/equatable.dart';

enum SyncStatus { signedOut, connected, syncing, pending, offline, error }

class SyncState extends Equatable {
  final SyncStatus status;
  final String? userName;
  final String? userEmail;
  final DateTime? lastSync;
  final int totalFiles;
  final int driveFiles;
  final int pendingFiles;
  final double progress;
  final bool autoSync;
  final bool offlineSync;

  final String? userPhotoUrl;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.signedOut,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    this.lastSync,
    this.totalFiles = 0,
    this.driveFiles = 0,
    this.pendingFiles = 0,
    this.progress = 0.0,
    this.autoSync = true,
    this.offlineSync = true,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    DateTime? lastSync,
    int? totalFiles,
    int? driveFiles,
    int? pendingFiles,
    double? progress,
    bool? autoSync,
    bool? offlineSync,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      lastSync: lastSync ?? this.lastSync,
      totalFiles: totalFiles ?? this.totalFiles,
      driveFiles: driveFiles ?? this.driveFiles,
      pendingFiles: pendingFiles ?? this.pendingFiles,
      progress: progress ?? this.progress,
      autoSync: autoSync ?? this.autoSync,
      offlineSync: offlineSync ?? this.offlineSync,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        userName,
        userEmail,
        userPhotoUrl,
        lastSync,
        totalFiles,
        driveFiles,
        pendingFiles,
        progress,
        autoSync,
        offlineSync,
        errorMessage,
      ];
}
