// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/connectivity_service.dart';
import '../../presentation/blocs/theme/theme_cubit.dart'; // Import ThemeCubit
import '../../presentation/blocs/selection/selection_cubit.dart';
import '../../services/hive_service.dart'; // Import HiveService
import '../../data/repositories/vault_repository_interface.dart'; // Import IVaultRepository
import '../../data/repositories/vault_repository_impl.dart'; // Import VaultRepositoryImpl
import '../../presentation/blocs/folders/folders_cubit.dart'; // Import FoldersBloc
import '../../presentation/blocs/files/files_cubit.dart'; // Import FilesBloc
import '../../presentation/blocs/notes/notes_cubit.dart'; // Import NotesCubit
import '../../presentation/blocs/sync/sync_cubit.dart'; // Import SyncCubit
import '../../services/auth/auth_service.dart'; // Import AuthService
import '../../services/google_drive_sync_service.dart'; // Import GoogleDriveSyncService
import 'package:flutter/foundation.dart'; // debugPrint import
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart'; // Import NoteModel
import 'package:notepad_pro/domain/repositories/note_repository.dart'; // Import INoteRepository
import 'package:notepad_pro/data/repositories/note_repository_impl.dart'; // Import NoteRepositoryImpl

final GetIt sl = GetIt.instance; // sl is short for Service Locator

Future<void> setupServiceLocator({
  required Box<FolderModel> folderBox,
  required Box<VaultFileModel> fileBox,
  required Box<NoteModel> noteBox,
  required Box<dynamic> appSettingsBox,
  required Box<dynamic> offlineModeBox,
}) async {
  // Register HiveService with debug checks
  assert(!sl.isRegistered<HiveService>(), 'HiveService already registered');
  debugPrint('setupServiceLocator: Registering HiveService');
    debugPrint(StackTrace.current.toString());
  sl.registerLazySingleton<HiveService>(() => HiveService(
        folderBox: folderBox,
        fileBox: fileBox,
        noteBox: noteBox,
        appSettingsBox: appSettingsBox,
      ));

  // Register ConnectivityService
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  // Register ThemeCubit
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sl()), // Inject HiveService
  );

  // Register AuthService
  sl.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  // Register GoogleDriveSyncService
  sl.registerLazySingleton<GoogleDriveSyncService>(
    () => GoogleDriveSyncService(sl(), sl()), // Inject AuthService and HiveService
  );
  // Register IVaultRepository
  sl.registerLazySingleton<IVaultRepository>(
    () => VaultRepositoryImpl(sl(), sl()), // Inject HiveService and GoogleDriveSyncService
  );

  // Register INoteRepository
  sl.registerLazySingleton<INoteRepository>(
    () => NoteRepositoryImpl(sl()), // Inject HiveService
  );


  sl.registerFactory<FoldersCubit>(
    () => FoldersCubit(sl(), sl()), // Inject IVaultRepository and SyncCubit
  );


  sl.registerFactory<FilesCubit>(
    () => FilesCubit(sl(), sl()), // Inject IVaultRepository and SyncCubit
  );

  // Register NotesCubit
  sl.registerFactory<NotesCubit>(
    () => NotesCubit(sl(), sl()), // Inject INoteRepository and SyncCubit
  );

  sl.registerFactory<SelectionCubit>(
    () => SelectionCubit(),
  );

  // Register SyncCubit
  sl.registerLazySingleton<SyncCubit>(
    () => SyncCubit(sl(), sl(), sl()),
  );

  // Initialize services that need it
  sl<ConnectivityService>().init(); // Initialize ConnectivityService
  // OfflineModeManager is initialized in its constructor with the box.
}

