import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/vault_file.dart' as domain_vault_file; // Alias the domain entity

part 'vault_file_model.g.dart';

const Object _sentinel = Object();

@HiveType(typeId: 1) // TypeId for ReferenceType enum in the data layer
enum ReferenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  video,
  @HiveField(2)
  book
}

@HiveType(typeId: 2)
class VaultFileModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? folderId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final ReferenceType referenceType; // Use data layer ReferenceType
  @HiveField(5)
  final String? videoTitle;
  @HiveField(6)
  final int? videoRefHours;
  @HiveField(7)
  final int? videoRefMinutes;
  @HiveField(8)
  final int? videoRefSeconds;
  @HiveField(9)
  final String? bookName;
  @HiveField(10)
  final String? authorName;
  @HiveField(11)
  final String? volume;
  @HiveField(12)
  final int? pageNumber;
  @HiveField(13)
  final int? lineNumber;
  @HiveField(14)
  final DateTime createdAt;
  @HiveField(15)
  final DateTime lastModified; // Renamed from updatedAt
  @HiveField(17)
  final String? driveFileId;
  @HiveField(18)
  final bool isSynced;

  const VaultFileModel({
    required this.id,
    this.folderId,
    required this.title,
    required this.description,
    this.referenceType = ReferenceType.none, // Use data layer ReferenceType
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
    required this.lastModified, // Renamed from updatedAt
    this.driveFileId,
    this.isSynced = false,
  });

  VaultFileModel copyWith({
    String? id,
    Object? folderId = _sentinel,
    String? title,
    Object? description = _sentinel,
    ReferenceType? referenceType,
    Object? videoTitle = _sentinel,
    Object? videoRefHours = _sentinel,
    Object? videoRefMinutes = _sentinel,
    Object? videoRefSeconds = _sentinel,
    Object? bookName = _sentinel,
    Object? authorName = _sentinel,
    Object? volume = _sentinel,
    Object? pageNumber = _sentinel,
    Object? lineNumber = _sentinel,
    DateTime? createdAt,
    DateTime? lastModified,
    Object? driveFileId = _sentinel,
    bool? isSynced,
  }) {
    return VaultFileModel(
      id: id ?? this.id,
      folderId: folderId == _sentinel ? this.folderId : folderId as String?,
      title: title ?? this.title,
      description: description == _sentinel ? this.description : description as String,
      referenceType: referenceType ?? this.referenceType,
      videoTitle: videoTitle == _sentinel ? this.videoTitle : videoTitle as String?,
      videoRefHours: videoRefHours == _sentinel ? this.videoRefHours : videoRefHours as int?,
      videoRefMinutes: videoRefMinutes == _sentinel ? this.videoRefMinutes : videoRefMinutes as int?,
      videoRefSeconds: videoRefSeconds == _sentinel ? this.videoRefSeconds : videoRefSeconds as int?,
      bookName: bookName == _sentinel ? this.bookName : bookName as String?,
      authorName: authorName == _sentinel ? this.authorName : authorName as String?,
      volume: volume == _sentinel ? this.volume : volume as String?,
      pageNumber: pageNumber == _sentinel ? this.pageNumber : pageNumber as int?,
      lineNumber: lineNumber == _sentinel ? this.lineNumber : lineNumber as int?,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      driveFileId: driveFileId == _sentinel ? this.driveFileId : driveFileId as String?,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props {
    return [
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
      lastModified, // Renamed from updatedAt
      driveFileId,
      isSynced,
    ];
  }

  // Conversion to entity
  domain_vault_file.VaultFile toEntity() { // Use aliased domain entity
    return domain_vault_file.VaultFile( // Use aliased domain entity
      id: id,
      folderId: folderId,
      title: title,
      description: description,
      referenceType: _mapReferenceTypeToDomain(referenceType), // Map to domain ReferenceType
      videoTitle: videoTitle,
      videoRefHours: videoRefHours,
      videoRefMinutes: videoRefMinutes,
      videoRefSeconds: videoRefSeconds,
      bookName: bookName,
      authorName: authorName,
      volume: volume,
      pageNumber: pageNumber,
      lineNumber: lineNumber,
      createdAt: createdAt,
      updatedAt: lastModified, // Map to domain updatedAt
      driveFileId: driveFileId,
      isSynced: isSynced,
    );
  }

  // Conversion from entity
  factory VaultFileModel.fromEntity(domain_vault_file.VaultFile entity) { // Use aliased domain entity
    return VaultFileModel(
      id: entity.id,
      folderId: entity.folderId,
      title: entity.title,
      description: entity.description,
      referenceType: _mapReferenceTypeFromDomain(entity.referenceType), // Map from domain ReferenceType
      videoTitle: entity.videoTitle,
      videoRefHours: entity.videoRefHours,
      videoRefMinutes: entity.videoRefMinutes,
      videoRefSeconds: entity.videoRefSeconds,
      bookName: entity.bookName,
      authorName: entity.authorName,
      volume: entity.volume,
      pageNumber: entity.pageNumber,
      lineNumber: entity.lineNumber,
      createdAt: entity.createdAt,
      lastModified: entity.updatedAt, // Map from domain updatedAt
      driveFileId: entity.driveFileId,
      isSynced: entity.isSynced,
    );
  }

  factory VaultFileModel.fromJson(Map<String, dynamic> json) {
    ReferenceType parsedRefType = ReferenceType.none;
    if (json['referenceType'] != null) {
      if (json['referenceType'] is int) {
        final index = json['referenceType'] as int;
        if (index >= 0 && index < ReferenceType.values.length) {
          parsedRefType = ReferenceType.values[index];
        }
      } else {
        parsedRefType = ReferenceType.values.firstWhere(
            (e) => e.toString().split('.').last == json['referenceType'],
            orElse: () => ReferenceType.none);
      }
    }

    return VaultFileModel(
      id: json['id'] is int ? json['id'].toString() : json['id'] as String,
      folderId: json['folderId'] == null
          ? null
          : (json['folderId'] is int ? json['folderId'].toString() : json['folderId'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      referenceType: parsedRefType,
      videoTitle: json['videoTitle'] as String?,
      videoRefHours: json['videoRefHours'] as int?,
      videoRefMinutes: json['videoRefMinutes'] as int?,
      videoRefSeconds: json['videoRefSeconds'] as int?,
      bookName: json['bookName'] as String?,
      authorName: json['authorName'] as String?,
      volume: json['volume'] as String?,
      pageNumber: json['pageNumber'] as int?,
      lineNumber: json['lineNumber'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      driveFileId: json['driveFileId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'description': description,
      'referenceType': referenceType.toString().split('.').last,
      'videoTitle': videoTitle,
      'videoRefHours': videoRefHours,
      'videoRefMinutes': videoRefMinutes,
      'videoRefSeconds': videoRefSeconds,
      'bookName': bookName,
      'authorName': authorName,
      'volume': volume,
      'pageNumber': pageNumber,
      'lineNumber': lineNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'driveFileId': driveFileId,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // Helper methods for mapping between data and domain ReferenceType
  static ReferenceType _mapReferenceTypeFromDomain(domain_vault_file.ReferenceType domainType) {
    switch (domainType) {
      case domain_vault_file.ReferenceType.none:
        return ReferenceType.none;
      case domain_vault_file.ReferenceType.video:
        return ReferenceType.video;
      case domain_vault_file.ReferenceType.book:
        return ReferenceType.book;
    }
  }

  static domain_vault_file.ReferenceType _mapReferenceTypeToDomain(ReferenceType dataType) {
    switch (dataType) {
      case ReferenceType.none:
        return domain_vault_file.ReferenceType.none;
      case ReferenceType.video:
        return domain_vault_file.ReferenceType.video;
      case ReferenceType.book:
        return domain_vault_file.ReferenceType.book;
    }
  }
}
