import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/create_bottom_sheet.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/empty_vault_view.dart';
import 'package:notepad_pro/presentation/widgets/app_logo.dart';
import 'package:notepad_pro/presentation/blocs/selection/selection_cubit.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/presentation/widgets/cards/file_card.dart';
import 'package:notepad_pro/presentation/widgets/cards/folder_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SelectionCubit(),
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  @override
  Widget build(BuildContext context) {
    final hiveService = sl<HiveService>();

    return ValueListenableBuilder(
      valueListenable: hiveService.folderBox.listenable(),
      builder: (context, Box<FolderModel> folderBox, _) {
        return ValueListenableBuilder(
          valueListenable: hiveService.fileBox.listenable(),
          builder: (context, Box<VaultFileModel> fileBox, _) {
            return ValueListenableBuilder(
              valueListenable: hiveService.noteBox.listenable(),
              builder: (context, Box<NoteModel> noteBox, _) {
                final rootFolders = folderBox.values
                    .where((f) => f.parentId == null || f.parentId == '')
                    .map((f) => f.toEntity())
                    .toList();

                final rootFiles = fileBox.values
                    .where((f) => f.folderId == null || f.folderId == '')
                    .map((f) => f.toEntity())
                    .toList();

                final rootNotes = noteBox.values
                    .where((n) => n.folderId == null || n.folderId == '')
                    .map((n) => n.toEntity())
                    .toList();

                final allItems = [...rootFolders, ...rootFiles, ...rootNotes];

                allItems.sort((a, b) {
                  final isAFolder = a.runtimeType.toString().contains('Folder');
                  final isBFolder = b.runtimeType.toString().contains('Folder');
                  if (isAFolder && !isBFolder) return -1;
                  if (!isAFolder && isBFolder) return 1;

                  String nameA = isAFolder ? (a as dynamic).name : (a as dynamic).title;
                  String nameB = isBFolder ? (b as dynamic).name : (b as dynamic).title;

                  return nameA.compareTo(nameB);
                });

                return BlocBuilder<SelectionCubit, SelectionState>(
                  builder: (context, selectionState) {
                    final isSelecting = selectionState.isSelecting;

                    if (allItems.isEmpty && !isSelecting) {
                      return const EmptyVaultView();
                    }

                    return PopScope(
                      canPop: !isSelecting,
                      onPopInvokedWithResult: (didPop, dynamic result) {
                        if (didPop) return;
                        if (isSelecting) {
                          context.read<SelectionCubit>().clearSelection();
                        }
                      },
                      child: Scaffold(
                      backgroundColor: const Color(0xFFF5F0FF),
                      body: SafeArea(
                        child: Column(
                          children: [
                            if (isSelecting)
                              _buildSelectionHeader(context, selectionState)
                            else
                              _buildDefaultHeader(context, rootFolders.length),
                            
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 20),
                                itemCount: allItems.length,
                                itemBuilder: (context, index) {
                                  final item = allItems[index];
                                  final typeStr = item.runtimeType.toString();
                                  if (typeStr.contains('Folder')) {
                                    return FolderCard(folder: item as dynamic);
                                  } else if (typeStr.contains('VaultFile')) {
                                    return FileCard(file: item as dynamic);
                                  } else {
                                    return ListTile(
                                      title: Text((item as dynamic).title ?? ''),
                                      subtitle: Text((item as dynamic).description ?? ''),
                                      onTap: () => context.push('/read-note', extra: {'file': item, 'highlightQuery': null}),
                                    );
                                  }
                                },
                              ),
                            ),
                            if (!isSelecting)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => showCreateBottomSheet(context),
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: const Text('Create new', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                                  ),
                                ),
                              )
                            else
                              _buildSelectionBottomBar(context, selectionState, allItems),
                          ],
                        ),
                      ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultHeader(BuildContext context, int folderCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const AppLogo(size: 18),
          const SizedBox(width: 8),
          const Text('NotePilot App', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF2D2540))),
          const Spacer(),
          _buildHeaderButton(icon: Icons.search, onPressed: () => context.push('/search')),
          const SizedBox(width: 8),
          _buildHeaderButton(icon: Icons.settings_outlined, onPressed: () => context.push('/settings')),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(BuildContext context, SelectionState state) {
    return AppBar(
      backgroundColor: const Color(0xFF6C5CE7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => context.read<SelectionCubit>().clearSelection(),
      ),
      title: Text(
        '${state.selectedIds.length} item${state.selectedIds.length > 1 ? "s" : ""} selected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500)),
      actions: [
        // Select all
        TextButton(
          onPressed: () {
            context.read<SelectionCubit>().selectAll(
              context.read<FoldersCubit>().state is FoldersLoadSuccess 
                ? (context.read<FoldersCubit>().state as FoldersLoadSuccess).folders.cast<dynamic>() 
                : [],
              context.read<FilesCubit>().state is FilesLoadSuccess 
                ? (context.read<FilesCubit>().state as FilesLoadSuccess).files.cast<dynamic>() 
                : []
            );
          },
          child: const Text("Sab",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13))),
      ],
    );
  }

  Widget _buildSelectionBottomBar(BuildContext context, SelectionState state, List<dynamic> allItems) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0D9F5), width: 0.5))),
      child: Row(children: [
        // Delete action
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final selectedItems = allItems.where((item) {
                final id = (item as dynamic).id;
                return state.selectedMap.containsKey(id);
              }).toList();

              if (selectedItems.isEmpty) return;

              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete Selected Items?'),
                  content: Text('Are you sure you want to delete ${selectedItems.length} item(s)? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        for (final item in selectedItems) {
                          final typeStr = item.runtimeType.toString();
                          if (typeStr.contains('Folder')) {
                            await context.read<FoldersCubit>().deleteFolder((item as dynamic).id);
                          } else if (typeStr.contains('VaultFile')) {
                            await context.read<FilesCubit>().deleteFile((item as dynamic).id);
                          }
                        }
                        if (context.mounted) {
                          context.read<SelectionCubit>().clearSelection();
                          context.read<FoldersCubit>().loadFolders();
                          context.read<FilesCubit>().loadFiles();
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFC0392B)),
            label: const Text("Delete", style: TextStyle(color: Color(0xFFC0392B))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFFFD5D5), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(width: 10),

        // Move action — primary
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () async {
              final selectedItems = allItems.where((item) {
                final id = (item as dynamic).id;
                return state.selectedMap.containsKey(id);
              }).toList();

              if (selectedItems.isNotEmpty) {
                final result = await context.push('/move-item', extra: selectedItems);
                if (result == true) {
                  if (context.mounted) {
                    context.read<SelectionCubit>().clearSelection();
                  }
                }
              }
            },
            icon: const Icon(Icons.drive_file_move_rounded, size: 16),
            label: const Text("Move"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6C5CE7)),
      ),
    );
  }
}
