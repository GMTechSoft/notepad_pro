import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';

class HiveService extends ChangeNotifier {
  static const String _initKey = 'is_app_initialized';
  static const String _restoreKey = 'manual_restore_performed';

  final Box<FolderModel> _folderBox;
  final Box<VaultFileModel> _fileBox;
  final Box<NoteModel> _noteBox;
  final Box<dynamic> _appSettingsBox;

  HiveService({
    required Box<FolderModel> folderBox,
    required Box<VaultFileModel> fileBox,
    required Box<NoteModel> noteBox,
    required Box<dynamic> appSettingsBox,
  })  : _folderBox = folderBox,
        _fileBox = fileBox,
        _noteBox = noteBox,
        _appSettingsBox = appSettingsBox;

  bool get isInitialized => _appSettingsBox.get(_initKey, defaultValue: false) as bool;
  bool get isManualRestorePerformed => _appSettingsBox.get(_restoreKey, defaultValue: false) as bool;

  // Box Access for ValueListenableBuilder
  Box<FolderModel> get folderBox => _folderBox;
  Box<VaultFileModel> get fileBox => _fileBox;
  Box<NoteModel> get noteBox => _noteBox;
  Box<dynamic> get appSettingsBox => _appSettingsBox;

  Future<void> setInitialized(bool value) async {
    await _appSettingsBox.put(_initKey, value);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  Future<void> refreshBoxes() async {
    notifyListeners();
  }

  Future<void> setManualRestorePerformed(bool value) async {
    await _appSettingsBox.put(_restoreKey, value);
    notifyListeners();
  }

  // Folder CRUD
  Future<void> addFolder(FolderModel folderModel) async {
    await _folderBox.put(folderModel.id, folderModel);
    notifyListeners();
  }

  Future<List<FolderModel>> getFolders() async {
    return _folderBox.values.toList();
  }

  Future<FolderModel?> getFolder(String id) async {
    return _folderBox.get(id);
  }

  Future<void> updateFolder(FolderModel folderModel) async {
    await _folderBox.put(folderModel.id, folderModel);
    notifyListeners();
  }

  Future<void> deleteFolder(String id) async {
    await _folderBox.delete(id);
    notifyListeners();
  }

  // Note CRUD
  Future<void> addNote(NoteModel noteModel) async {
    await _noteBox.put(noteModel.id, noteModel);
    notifyListeners();
  }

  Future<List<NoteModel>> getNotes() async {
    return _noteBox.values.toList();
  }

  Future<NoteModel?> getNote(String id) async {
    return _noteBox.get(id);
  }

  Future<void> updateNote(NoteModel noteModel) async {
    await _noteBox.put(noteModel.id, noteModel);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _noteBox.delete(id);
    notifyListeners();
  }

  // File CRUD
  Future<void> addFile(VaultFileModel fileModel) async {
    await _fileBox.put(fileModel.id, fileModel);
    notifyListeners();
  }

  Future<List<VaultFileModel>> getFiles() async {
    return _fileBox.values.toList();
  }

  Future<VaultFileModel?> getFile(String id) async {
    return _fileBox.get(id);
  }

  Future<void> updateFile(VaultFileModel fileModel) async {
    await _fileBox.put(fileModel.id, fileModel);
    notifyListeners();
  }

  Future<void> deleteFile(String id) async {
    await _fileBox.delete(id);
    notifyListeners();
  }

  // Unsynced data retrieval
  List<FolderModel> getUnsyncedFolders() => _folderBox.values.where((f) => !f.isSynced).toList();
  List<NoteModel> getUnsyncedNotes() => _noteBox.values.where((n) => !n.isSynced).toList();
  List<VaultFileModel> getUnsyncedFiles() => _fileBox.values.where((f) => !f.isSynced).toList();

  // Efficient Restore
  Future<void> restoreData({
    required List<FolderModel> folders,
    required List<NoteModel> notes,
    required List<VaultFileModel> files,
  }) async {
    debugPrint('restoreData called');
    debugPrintInfo('Before restoreData');
    await _folderBox.clear();
    await _noteBox.clear();
    await _fileBox.clear();

    final folderMap = {for (var f in folders) f.id: f};
    final noteMap = {for (var n in notes) n.id: n};
    final fileMap = {for (var f in files) f.id: f};

    await _folderBox.putAll(folderMap);
    await _noteBox.putAll(noteMap);
    await _fileBox.putAll(fileMap);

    await setManualRestorePerformed(true);
    await setInitialized(true);
    debugPrintInfo('After restoreData');
    notifyListeners();
  }

  // Debug helper method
  void debugPrintInfo(String context) {
    final serviceHash = this.hashCode;
    final folderBoxHash = _folderBox.hashCode;
    final fileBoxHash = _fileBox.hashCode;
    final folderCount = _folderBox.length;
    final fileCount = _fileBox.length;
    debugPrint('--- DebugInfo [$context] ---');
    debugPrint('HiveService hashCode: $serviceHash');
    debugPrint('folderBox hashCode: $folderBoxHash');
    debugPrint('fileBox hashCode: $fileBoxHash');
    debugPrint('folder count: $folderCount');
    debugPrint('file count: $fileCount');
    for (var f in _folderBox.values) {
      debugPrint('Folder -> id: ${f.id}, name: ${f.name}, parentId: ${f.parentId}');
    }
    for (var file in _fileBox.values) {
      debugPrint('File -> id: ${file.id}, title: ${file.title}, folderId: ${file.folderId}');
    }
    debugPrint('--- End DebugInfo [$context] ---');
    // Print stack trace  // Nuclear Restore Pattern
  }

  Future<void> clearAllData() async {
    await _folderBox.clear();
    await _fileBox.clear();
    await _noteBox.clear();
    await setInitialized(false);
    await setManualRestorePerformed(false);
    notifyListeners();
  }


}
