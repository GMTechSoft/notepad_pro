import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final String id;
  final String? folderId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driveFileId;
  final bool isSynced;

  const NoteEntity({
    required this.id,
    this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.driveFileId,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [id, folderId, title, content, createdAt, updatedAt, driveFileId, isSynced];

  NoteEntity copyWith({
    String? id,
    String? folderId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driveFileId,
    bool? isSynced,
  }) {
    return NoteEntity(
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
}
