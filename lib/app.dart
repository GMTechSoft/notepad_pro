import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/core/routes/app_router.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/notes/notes_cubit.dart'; // Import NotesCubit
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart'; // Import SyncCubit

import 'package:notepad_pro/presentation/blocs/theme/theme_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider<FoldersCubit>(create: (context) => sl<FoldersCubit>()..loadFolders()),
        BlocProvider<FilesCubit>(create: (context) => sl<FilesCubit>()..loadFiles()),
        BlocProvider<NotesCubit>(create: (context) => sl<NotesCubit>()..loadNotes()), // Add NotesCubit
        BlocProvider<SyncCubit>(create: (context) => sl<SyncCubit>()), // Add SyncCubit
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'Notepad Pro',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: ThemeData(
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: const Color(0xFFF5F0FF),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6C5CE7),
                    brightness: Brightness.light,
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: const Color(0xFF1A1625),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6C5CE7),
                    brightness: Brightness.dark,
                  ),
                ),
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}
