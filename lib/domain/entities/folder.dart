import 'package:equatable/equatable.dart';

class Folder extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? colorValue;
  final int? lightBgColorValue;
  final int? darkIconColorValue;
  final String? driveFileId;
  final bool isSynced;

  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
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
        updatedAt,
        colorValue,
        lightBgColorValue,
        darkIconColorValue,
        driveFileId,
        isSynced,
      ];

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorValue,
    int? lightBgColorValue,
    int? darkIconColorValue,
    String? driveFileId,
    bool? isSynced,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
      lightBgColorValue: lightBgColorValue ?? this.lightBgColorValue,
      darkIconColorValue: darkIconColorValue ?? this.darkIconColorValue,
      driveFileId: driveFileId ?? this.driveFileId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
