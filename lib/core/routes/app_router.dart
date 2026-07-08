import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/screens/create_file/create_file_screen.dart';
import 'package:notepad_pro/presentation/screens/folder_detail/folder_detail_screen.dart';
import 'package:notepad_pro/presentation/screens/home/home_screen.dart';
import 'package:notepad_pro/presentation/screens/editor/note_editor_screen.dart';
import 'package:notepad_pro/presentation/screens/note_reader/read_note_screen.dart';
import 'package:notepad_pro/presentation/screens/settings/settings_screen.dart';
import 'package:notepad_pro/presentation/screens/search/search_screen.dart';
import 'package:notepad_pro/presentation/screens/splash_screen.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';
import 'package:notepad_pro/presentation/blocs/theme/theme_cubit.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        name: 'splash',
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'folder',
        path: '/folder/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FolderDetailScreen(folderId: id);
        },
      ),
      GoRoute(
        name: 'create-file',
        path: '/create-file',
        builder: (context, state) {
          final folderId = state.uri.queryParameters['folderId'];
          final initialFile = state.extra as VaultFile?;
          return CreateFileScreen(folderId: folderId, initialFile: initialFile);
        },
      ),
      GoRoute(
        name: 'create-note',
        path: '/create-note',
        builder: (context, state) {
          final folderId = state.uri.queryParameters['folderId'];
          return CreateFileScreen(folderId: folderId);
        },
      ),
      GoRoute(
        name: 'note-editor',
        path: '/note-editor/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoteEditorScreen(noteId: id);
        },
      ),
      GoRoute(
        name: 'read-note',
        path: '/read-note',
        builder: (context, state) {
          final file = state.extra as VaultFile;
          return ReadNoteScreen(file: file);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<SyncCubit>()),
            BlocProvider.value(value: context.read<ThemeCubit>()),
          ],
          child: const SettingsScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error?.message}'),
      ),
    ),
  );
}

