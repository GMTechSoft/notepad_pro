// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_file_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaultFileModelAdapter extends TypeAdapter<VaultFileModel> {
  @override
  final int typeId = 2;

  @override
  VaultFileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaultFileModel(
      id: fields[0] as String,
      folderId: fields[1] as String?,
      title: fields[2] as String? ?? 'Untitled',
      description: fields[3] as String? ?? '',
      referenceType: fields[4] as ReferenceType? ?? ReferenceType.none,
      videoTitle: fields[5] as String?,
      videoRefHours: fields[6] as int?,
      videoRefMinutes: fields[7] as int?,
      videoRefSeconds: fields[8] as int?,
      bookName: fields[9] as String?,
      authorName: fields[10] as String?,
      volume: fields[11] as String?,
      pageNumber: fields[12] as int?,
      lineNumber: fields[13] as int?,
      createdAt: fields[14] as DateTime? ?? DateTime.now(),
      lastModified: fields[15] as DateTime? ?? DateTime.now(),
      driveFileId: fields[17] as String?,
      isSynced: fields[18] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, VaultFileModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.referenceType)
      ..writeByte(5)
      ..write(obj.videoTitle)
      ..writeByte(6)
      ..write(obj.videoRefHours)
      ..writeByte(7)
      ..write(obj.videoRefMinutes)
      ..writeByte(8)
      ..write(obj.videoRefSeconds)
      ..writeByte(9)
      ..write(obj.bookName)
      ..writeByte(10)
      ..write(obj.authorName)
      ..writeByte(11)
      ..write(obj.volume)
      ..writeByte(12)
      ..write(obj.pageNumber)
      ..writeByte(13)
      ..write(obj.lineNumber)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.lastModified)
      ..writeByte(17)
      ..write(obj.driveFileId)
      ..writeByte(18)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultFileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReferenceTypeAdapter extends TypeAdapter<ReferenceType> {
  @override
  final int typeId = 1;

  @override
  ReferenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReferenceType.none;
      case 1:
        return ReferenceType.video;
      case 2:
        return ReferenceType.book;
      default:
        return ReferenceType.none;
    }
  }

  @override
  void write(BinaryWriter writer, ReferenceType obj) {
    switch (obj) {
      case ReferenceType.none:
        writer.writeByte(0);
        break;
      case ReferenceType.video:
        writer.writeByte(1);
        break;
      case ReferenceType.book:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
