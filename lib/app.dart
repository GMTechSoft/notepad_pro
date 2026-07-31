import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/core/routes/app_router.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/notes/notes_cubit.dart'; // Import NotesCubit
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart'; // Import SyncCubit

class App extends StatelessWidget {
  const App({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FoldersCubit>(create: (context) => sl<FoldersCubit>()..loadFolders()),
        BlocProvider<FilesCubit>(create: (context) => sl<FilesCubit>()..loadFiles()),
        BlocProvider<NotesCubit>(create: (context) => sl<NotesCubit>()..loadNotes()), // Add NotesCubit
        BlocProvider<SyncCubit>(create: (context) => sl<SyncCubit>()), // Add SyncCubit
      ],
      child: MaterialApp.router(
        title: 'NotePilot',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F0FF),
          cardColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF6C5CE7),
            surface: Colors.white,
            onSurface: const Color(0xFF2D2540),
            onSurfaceVariant: const Color(0xFF9B8DB8),
            primaryContainer: const Color(0xFFEDE9F8),
            onPrimaryContainer: const Color(0xFF6C5CE7),
            outline: const Color(0xFFE0D9F5),
            outlineVariant: const Color(0xFFF5F0FF),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1625),
          cardColor: const Color(0xFF252033),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF6C5CE7),
            surface: const Color(0xFF252033),
            onSurface: const Color(0xFFEDE9F8),
            onSurfaceVariant: const Color(0xFF9B8DB8),
            primaryContainer: const Color(0xFF3B3354),
            onPrimaryContainer: const Color(0xFFEDE9F8),
            outline: const Color(0xFF3B3354),
            outlineVariant: const Color(0xFF1A1625),
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}

