import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io'; // Import for Directory

import 'package:notepad_pro/app.dart';
import 'package:notepad_pro/core/di/service_locator.dart'; // Import sl
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for tests with a temporary directory
    final path = '${Directory.current.path}/test_hive_db';
    Hive.init(path);
    
    // Open required boxes for service locator
    final folderBox = await Hive.openBox<FolderModel>('folders');
    final fileBox = await Hive.openBox<VaultFileModel>('files');
    final noteBox = await Hive.openBox<NoteModel>('notes');
    final appSettingsBox = await Hive.openBox<dynamic>('appSettings');
    final offlineModeBox = await Hive.openBox<dynamic>('offlineModeBox');

    // Call the service locator setup after Hive is initialized in tests
    await setupServiceLocator(
      folderBox: folderBox,
      fileBox: fileBox,
      noteBox: noteBox,
      appSettingsBox: appSettingsBox,
      offlineModeBox: offlineModeBox,
    );
    await sl.allReady(); // Ensure all async singletons are ready using sl
  });

  tearDownAll(() async {
    // Clean up Hive boxes and data after all tests are done
    await Hive.deleteFromDisk();
    // Delete the temporary directory as well
    await Directory('${Directory.current.path}/test_hive_db').delete(recursive: true);
    // Reset GetIt instance for a clean state in case of multiple test runs
    await sl.reset();
  });

  testWidgets('App starts with "NotePilot" text', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle(); // Allow initial screen to render

    expect(find.text('NotePilot'), findsOneWidget);

    // Advance the clock to allow the Future.delayed in AppStartupScreen to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(); // Allow navigation to WelcomeScreen to complete
  });
}
