import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad_pro/app.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/presentation/blocs/theme/theme_cubit.dart';

void main() async {
  // Requirement: Ensure WidgetsFlutterBinding.ensureInitialized() is the very first line
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    debugPrint('[Main] Starting initialization...');
    
    // 1. Initialize Hive with timeout
    await Hive.initFlutter().timeout(const Duration(seconds: 5));

    // 2. Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FolderModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(VaultFileModelAdapter());
    if (!Hive.isAdapterRegistered(33)) Hive.registerAdapter(ReferenceTypeAdapter());
    if (!Hive.isAdapterRegistered(100)) Hive.registerAdapter(NoteModelAdapter());

    // 3. Open Boxes with timeout and safety checks
    final folderBox = Hive.isBoxOpen('folders') 
        ? Hive.box<FolderModel>('folders') 
        : await Hive.openBox<FolderModel>('folders').timeout(const Duration(seconds: 7));
        
    final fileBox = Hive.isBoxOpen('files') 
        ? Hive.box<VaultFileModel>('files') 
        : await Hive.openBox<VaultFileModel>('files').timeout(const Duration(seconds: 7));
        
    final noteBox = Hive.isBoxOpen('notes') 
        ? Hive.box<NoteModel>('notes') 
        : await Hive.openBox<NoteModel>('notes').timeout(const Duration(seconds: 7));
        
    final notesSettingsBox = Hive.isBoxOpen('notes_settings') 
        ? Hive.box<dynamic>('notes_settings') 
        : await Hive.openBox<dynamic>('notes_settings').timeout(const Duration(seconds: 7));
        
    final offlineModeBox = Hive.isBoxOpen('offlineModeBox') 
        ? Hive.box<dynamic>('offlineModeBox') 
        : await Hive.openBox<dynamic>('offlineModeBox').timeout(const Duration(seconds: 7));

    // 4. Setup Service Locator with timeout
    await setupServiceLocator(
      folderBox: folderBox,
      fileBox: fileBox,
      noteBox: noteBox,
      appSettingsBox: notesSettingsBox,
      offlineModeBox: offlineModeBox,
    ).timeout(const Duration(seconds: 15));

    // 5. Handle First Run Clean Slate
    await _handleFirstRun(notesSettingsBox, folderBox, fileBox, noteBox);

    await sl<ThemeCubit>().loadFromPrefs();

    debugPrint('[Main] Initialization complete.');
  } catch (e, stack) {
    debugPrint('[Main] Initialization Error: $e');
    debugPrint(stack.toString());
    
    FlutterNativeSplash.remove(); // Ensure splash is removed so error is visible
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Text(
                  'Initialization Failed:\n\n$e\n\n$stack',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return; // Halt execution so `runApp(const App())` isn't called with an empty GetIt
  }

  runApp(const App());
}

Future<void> _handleFirstRun(
  Box<dynamic> appSettingsBox,
  Box<FolderModel> folderBox,
  Box<VaultFileModel> fileBox,
  Box<NoteModel> noteBox,
) async {
  const String isFirstRunKey = 'is_first_run_final';
  final bool isFirstRun = appSettingsBox.get(isFirstRunKey, defaultValue: true) as bool;

  if (isFirstRun) {
    debugPrint('[Main] First Run Detected: Enforcing clean slate.');
    await folderBox.clear();
    await fileBox.clear();
    await noteBox.clear();
    
    await appSettingsBox.put(isFirstRunKey, false);
    debugPrint('[Main] Clean slate enforced.');
  }
}

