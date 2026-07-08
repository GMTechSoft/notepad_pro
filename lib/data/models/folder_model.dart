import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/folder.dart'; // Import the Folder entity

part 'folder_model.g.dart';

const Object _sentinel = Object();

@HiveType(typeId: 0)
class FolderModel extends Equatable { // Renamed to FolderModel
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? parentId;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime lastModified; // Renamed from updatedAt
  @HiveField(5)
  final int? colorValue;
  @HiveField(6)
  final int? lightBgColorValue;
  @HiveField(7)
  final String? driveFileId;
  @HiveField(8)
  final bool isSynced;
  @HiveField(9)
  final int? darkIconColorValue;

  const FolderModel({ // Renamed to FolderModel
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.lastModified, // Renamed from updatedAt
    this.colorValue,
    this.lightBgColorValue,
    this.darkIconColorValue,
    this.driveFileId,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        createdAt,
        lastModified,
        colorValue,
        lightBgColorValue,
        darkIconColorValue,
        driveFileId,
        isSynced
      ];

  FolderModel copyWith({ // Renamed to FolderModel
    String? id,
    String? name,
    Object? parentId = _sentinel,
    DateTime? createdAt,
    DateTime? lastModified, // Renamed from updatedAt
    Object? colorValue = _sentinel,
    Object? lightBgColorValue = _sentinel,
    Object? darkIconColorValue = _sentinel,
    Object? driveFileId = _sentinel,
    bool? isSynced,
  }) {
    return FolderModel( // Renamed to FolderModel
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId == _sentinel ? this.parentId : parentId as String?,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified, // Renamed from updatedAt
      colorValue: colorValue == _sentinel ? this.colorValue : colorValue as int?,
      lightBgColorValue: lightBgColorValue == _sentinel ? this.lightBgColorValue : lightBgColorValue as int?,
      darkIconColorValue: darkIconColorValue == _sentinel ? this.darkIconColorValue : darkIconColorValue as int?,
      driveFileId: driveFileId == _sentinel ? this.driveFileId : driveFileId as String?,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Conversion to entity
  Folder toEntity() {
    return Folder(
      id: id,
      name: name,
      parentId: parentId,
      createdAt: createdAt,
      updatedAt: lastModified, // Map to entity's updatedAt
      colorValue: colorValue,
      lightBgColorValue: lightBgColorValue,
      darkIconColorValue: darkIconColorValue,
      driveFileId: driveFileId,
      isSynced: isSynced,
    );
  }

  // Conversion from entity
  factory FolderModel.fromEntity(Folder entity) {
    return FolderModel(
      id: entity.id,
      name: entity.name,
      parentId: entity.parentId,
      createdAt: entity.createdAt,
      lastModified: entity.updatedAt, // Map from entity's updatedAt
      colorValue: entity.colorValue,
      lightBgColorValue: entity.lightBgColorValue,
      darkIconColorValue: entity.darkIconColorValue,
      driveFileId: entity.driveFileId,
      isSynced: entity.isSynced,
    );
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Folder',
      parentId: json['parentId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastModified: DateTime.tryParse(json['lastModified']?.toString() ?? json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      colorValue: json['colorValue'] as int?,
      lightBgColorValue: json['lightBgColorValue'] as int?,
      darkIconColorValue: json['darkIconColorValue'] as int?,
      driveFileId: json['driveFileId']?.toString(),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(), // Renamed from updatedAt
      'colorValue': colorValue,
      'lightBgColorValue': lightBgColorValue,
      'darkIconColorValue': darkIconColorValue,
      'driveFileId': driveFileId,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}