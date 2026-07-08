import 'package:equatable/equatable.dart';

enum ReferenceType {
  none,
  video,
  book
}

class VaultFile extends Equatable {
  final String id;
  final String? folderId;
  final String title;
  final String description;
  final ReferenceType referenceType;
  final String? videoTitle;
  final int? videoRefHours;
  final int? videoRefMinutes;
  final int? videoRefSeconds;
  final String? bookName;
  final String? authorName;
  final String? volume;
  final int? pageNumber;
  final int? lineNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driveFileId;
  final bool isSynced;

  const VaultFile({
    required this.id,
    this.folderId,
    required this.title,
    required this.description,
    this.referenceType = ReferenceType.none,
    this.videoTitle,
    this.videoRefHours,
    this.videoRefMinutes,
    this.videoRefSeconds,
    this.bookName,
    this.authorName,
    this.volume,
    this.pageNumber,
    this.lineNumber,
    required this.createdAt,
    required this.updatedAt,
    this.driveFileId,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
    id,
    folderId,
    title,
    description,
    referenceType,
    videoTitle,
    videoRefHours,
    videoRefMinutes,
    videoRefSeconds,
    bookName,
    authorName,
    volume,
    pageNumber,
    lineNumber,
    createdAt,
    updatedAt,
    driveFileId,
    isSynced,
  ];

  VaultFile copyWith({
    String? id,
    String? folderId,
    String? title,
    String? description,
    ReferenceType? referenceType,
    String? videoTitle,
    int? videoRefHours,
    int? videoRefMinutes,
    int? videoRefSeconds,
    String? bookName,
    String? authorName,
    String? volume,
    int? pageNumber,
    int? lineNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driveFileId,
    bool? isSynced,
  }) {
    return VaultFile(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      description: description ?? this.description,
      referenceType: referenceType ?? this.referenceType,
      videoTitle: videoTitle ?? this.videoTitle,
      videoRefHours: videoRefHours ?? this.videoRefHours,
      videoRefMinutes: videoRefMinutes ?? this.videoRefMinutes,
      videoRefSeconds: videoRefSeconds ?? this.videoRefSeconds,
      bookName: bookName ?? this.bookName,
      authorName: authorName ?? this.authorName,
      volume: volume ?? this.volume,
      pageNumber: pageNumber ?? this.pageNumber,
      lineNumber: lineNumber ?? this.lineNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driveFileId: driveFileId ?? this.driveFileId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
