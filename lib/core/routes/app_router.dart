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
import 'package:notepad_pro/presentation/screens/folders/move_item_screen.dart';

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
        path: '/move-item',
        builder: (context, state) => MoveItemScreen(itemsToMove: state.extra as List<dynamic>),
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
          VaultFile? file;
          String? query;
          List<String>? highlightWords;
          String? searchMode;
          Map<String, Color>? highlightColors;
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            file = extra['file'] as VaultFile?;
            query = extra['highlightQuery'] as String?;
            highlightWords = (extra['highlightWords'] as List<dynamic>?)?.cast<String>();
            searchMode = extra['searchMode'] as String?;
            highlightColors = extra['highlightColors'] as Map<String, Color>?;
          } else if (extra is VaultFile) {
            file = extra;
          }
          // Provide a default placeholder file to avoid null crashes
          file ??= VaultFile(
            id: '',
            title: '',
            description: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            referenceType: ReferenceType.none,
          );
          return ReadNoteScreen(
            file: file,
            highlightQuery: query,
            highlightWords: highlightWords,
            searchMode: searchMode,
            highlightColors: highlightColors,
          );
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final Map<String, dynamic> extraArgs = state.extra as Map<String, dynamic>? ?? {};
          final String initialQuery = extraArgs['initialQuery'] as String? ?? '';
          final String? folderId = extraArgs['folderId'] as String?;
          return SearchScreen(initialQuery: initialQuery, folderId: folderId);
        },

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

