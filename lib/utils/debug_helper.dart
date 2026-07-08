import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../services/hive_service.dart';

/// Prints all stored Hive data (folders, files, notes) to the console.
Future<void> debugPrintAllData() async {
  final GetIt sl = GetIt.instance;
  if (!sl.isRegistered<HiveService>()) {
    debugPrint('HiveService not registered');
    return;
  }
  final hiveService = sl<HiveService>();
  debugPrint('=== DEBUG PRINT ALL DATA ===');
  debugPrint('--- Folders (${hiveService.folderBox.length}) ---');
  for (final f in hiveService.folderBox.values) {
    debugPrint(f.toString());
  }
  debugPrint('--- Files (${hiveService.fileBox.length}) ---');
  for (final f in hiveService.fileBox.values) {
    debugPrint(f.toString());
  }
  debugPrint('--- Notes (${hiveService.noteBox.length}) ---');
  for (final n in hiveService.noteBox.values) {
    debugPrint(n.toString());
  }
  debugPrint('=== END DEBUG PRINT ===');
}
