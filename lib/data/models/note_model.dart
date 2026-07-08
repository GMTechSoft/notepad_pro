import 'package:hive/hive.dart';
import 'package:notepad_pro/domain/entities/note_entity.dart';

part 'note_model.g.dart'; // Generated adapter file

@HiveType(typeId: 100) // Assign a unique typeId
class NoteModel extends NoteEntity {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime updatedAt;
  @HiveField(5)
  final String? driveFileId;
  @HiveField(6)
  final bool isSynced;
  @HiveField(7)
  final String? folderId;

  const NoteModel({
    required this.id,
    this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.driveFileId,
    this.isSynced = false,
  }) : super(id: id, folderId: folderId, title: title, content: content, createdAt: createdAt, updatedAt: updatedAt, driveFileId: driveFileId, isSynced: isSynced);

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      folderId: entity.folderId,
      title: entity.title,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      driveFileId: entity.driveFileId,
      isSynced: entity.isSynced,
    );
  }

  NoteEntity toEntity() {
    return NoteEntity(
      id: id,
      folderId: folderId,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      driveFileId: driveFileId,
      isSynced: isSynced,
    );
  }

  @override
  NoteModel copyWith({
    String? id,
    String? folderId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driveFileId,
    bool? isSynced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driveFileId: driveFileId ?? this.driveFileId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id']?.toString() ?? '',
      folderId: json['folderId']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      driveFileId: json['driveFileId']?.toString(),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'driveFileId': driveFileId,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}

