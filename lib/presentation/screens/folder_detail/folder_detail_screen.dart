import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/presentation/widgets/cards/file_card.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/create_bottom_sheet.dart';
import 'package:notepad_pro/presentation/widgets/cards/folder_card.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/selection/selection_cubit.dart';

import '../../blocs/files/files_cubit.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  const FolderDetailScreen({super.key, required this.folderId});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  String? _loadedFolderId;

  String? get _effectiveFolderId => widget.folderId.isEmpty ? null : widget.folderId;

  @override
  void initState() {
    super.initState();
    _loadActiveFolderFiles();
  }

  @override
  void didUpdateWidget(covariant FolderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folderId != widget.folderId) {
      _loadActiveFolderFiles();
    }
  }

  void _loadActiveFolderFiles() {
    final effectiveFolderId = _effectiveFolderId;
    if (_loadedFolderId == effectiveFolderId) return;
    _loadedFolderId = effectiveFolderId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FilesCubit>().loadFilesForFolder(effectiveFolderId);
    });
  }

  void _showCreateOptions(BuildContext context) {
    showCreateBottomSheet(context, parentFolderId: widget.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = sl<HiveService>();
    final folderId = widget.folderId;
    final effectiveFolderId = _effectiveFolderId;
    
    return BlocProvider<SelectionCubit>(
      create: (context) => SelectionCubit(),
      child: Builder(
        builder: (context) {
          return ValueListenableBuilder(
            valueListenable: hiveService.folderBox.listenable(),
            builder: (context, Box<FolderModel> folderBox, _) {
              final currentFolderModel = effectiveFolderId != null ? folderBox.get(effectiveFolderId) : null;

              if (currentFolderModel == null && effectiveFolderId != null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: const Center(child: Text('Folder not found.')),
                );
              }

              return BlocBuilder<SelectionCubit, SelectionState>(
                builder: (context, selectionState) {
                  final isSelecting = selectionState.isSelecting;

                  return WillPopScope(
                    onWillPop: () async {
                      if (!isSelecting) return true;
                      context.read<SelectionCubit>().clearSelection();
                      return false;
                    },
                    child: Scaffold(
                backgroundColor: const Color(0xFFF5F0FF),
                appBar: isSelecting 
                  ? AppBar(
                      backgroundColor: const Color(0xFF6C5CE7),
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.read<SelectionCubit>().clearSelection(),
                      ),
                      title: Text(
                        '${selectionState.selectedIds.length} item${selectionState.selectedIds.length > 1 ? "s" : ""} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            context.read<SelectionCubit>().selectAll(
                              context.read<FoldersCubit>().state is FoldersLoadSuccess ? (context.read<FoldersCubit>().state as FoldersLoadSuccess).folders.cast<dynamic>() : [],
                              context.read<FilesCubit>().state is FilesLoadSuccess ? (context.read<FilesCubit>().state as FilesLoadSuccess).files.cast<dynamic>() : []
                            );
                          },
                          child: const Text("Sab",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13))),
                      ],
                    )
                  : AppBar(
                      backgroundColor: const Color(0xFFF5F0FF),
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      title: Row(children: [
                        InkWell(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDE9F8),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF6C5CE7)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(currentFolderModel?.name ?? 'Root Folder',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D2540))),
                      ]),
                      actions: [
                        InkWell(
                          onTap: () => context.push('/search', extra: {'initialQuery': '', 'folderId': folderId}),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDE9F8),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.search, size: 14, color: Color(0xFF6C5CE7)),
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/settings'),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDE9F8),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.settings_outlined, size: 14, color: Color(0xFF6C5CE7)),
                          ),
                        ),
                      ],
                    ),
                body: BlocBuilder<FilesCubit, FilesState>(
                  builder: (context, state) {
                    if (state is FilesInitial || state is FilesLoadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final subfolders = folderBox.values
                        .where((f) => f.parentId == effectiveFolderId)
                        .map((f) => f.toEntity())
                        .toList();

                    if (state is FilesLoadFailure) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text("0 items", style: TextStyle(fontSize: 11, color: Color(0xFF9B8DB8))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF9B8DB8)),
                              ),
                            ),
                          ),
                          if (!isSelecting) _buildBottomCreateButton(context)
                          else _buildSelectionBottomBar(context, selectionState, []),
                        ],
                      );
                    }

                    if (state is! FilesLoadSuccess) {
                      return const SizedBox.shrink();
                    }

                    final List<dynamic> files = [];
                    for (var f in state.files) {
                      try {
                        final String? fFolderId = (f as dynamic).folderId?.toString();
                        final String? targetFolderId = effectiveFolderId?.toString();
                        if (fFolderId == targetFolderId) {
                          files.add(f);
                        }
                      } catch (_) {}
                    }

                    final allItems = [...subfolders, ...files];

                    if (allItems.isEmpty && !isSelecting) {
                      return _buildEmptyState(context, isSelecting: isSelecting, state: selectionState, allItems: allItems);
                    }

                    try {
                      allItems.sort((a, b) {
                        final isAFolder = a is Folder;
                        final isBFolder = b is Folder;
                        if (isAFolder && !isBFolder) return -1;
                        if (!isAFolder && isBFolder) return 1;

                        String nameA = '';
                        String nameB = '';

                        try {
                          nameA = isAFolder ? a.name : ((a as dynamic).title?.toString() ?? (a as dynamic).name?.toString() ?? '');
                        } catch (_) {}

                        try {
                          nameB = isBFolder ? b.name : ((b as dynamic).title?.toString() ?? (b as dynamic).name?.toString() ?? '');
                        } catch (_) {}

                        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                      });
                    } catch (_) {}

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${allItems.length} items",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF9B8DB8))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              if (item is Folder) {
                                return FolderCard(folder: item);
                              } else {
                                try {
                                  if (item is VaultFile) {
                                    return FileCard(file: item);
                                  }
                                  final dynamic dItem = item;
                                  final fallbackFile = VaultFile(
                                    id: dItem.id?.toString() ?? '',
                                    folderId: dItem.folderId?.toString(),
                                    title: dItem.title?.toString() ?? dItem.name?.toString() ?? 'Untitled Note',
                                    description: dItem.description?.toString() ?? '',
                                    createdAt: dItem.createdAt ?? DateTime.now(),
                                    updatedAt: dItem.updatedAt ?? DateTime.now(),
                                  );
                                  return FileCard(file: fallbackFile);
                                } catch (e) {
                                  return const SizedBox.shrink();
                                }
                              }
                            },
                          ),
                        ),
                        if (!isSelecting) _buildBottomCreateButton(context)
                        else _buildSelectionBottomBar(context, selectionState, allItems),
                      ],
                    );
                  },
                ),
                  ));
                },
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isSelecting = false, SelectionState? state, List<dynamic>? allItems}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("0 items", style: TextStyle(fontSize: 11, color: Color(0xFF9B8DB8))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text("Empty",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6C5CE7))),
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.folder_open_outlined, size: 28, color: Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 14),
            const Text("Folder khali hai",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D2540))),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                  "Is folder mein abhi kuch nahi.\nNaya note ya folder banayein.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9B8DB8), height: 1.6)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  icon: Icons.note_add_outlined,
                  label: "Note",
                  onTap: () => context.push('/create-note?folderId=${widget.folderId}'),
                ),
                const SizedBox(width: 8),
                _chip(
                  icon: Icons.create_new_folder_outlined,
                  label: "Sub-folder",
                  onTap: () async {
                    final result = await showCreateFolderDialog(context);
                    if (result != null && result['name'] != null && (result['name'] as String).isNotEmpty) {
                      if (!context.mounted) return;
                      await context.read<FoldersCubit>().createFolder(
                            result['name'] as String,
                            widget.folderId,
                            result['colorValue'] as int?,
                            lightBgColorValue: result['lightBgColorValue'] as int?,
                            darkIconColorValue: result['darkIconColorValue'] as int?,
                          );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      if (!isSelecting) _buildBottomCreateButton(context)
      else if (state != null && allItems != null) _buildSelectionBottomBar(context, state, allItems),
    ]);
  }

  Widget _buildBottomCreateButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Create new", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6C5CE7)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6C5CE7))),
          ],
        ),
      ),
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
}