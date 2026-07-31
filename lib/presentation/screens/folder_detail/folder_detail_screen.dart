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
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/selection/selection_cubit.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

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

              return BlocBuilder<FilesCubit, FilesState>(
                builder: (context, filesState) {
                  final currentFolderModel = effectiveFolderId != null ? folderBox.get(effectiveFolderId) : null;

                  if (currentFolderModel == null && effectiveFolderId != null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(child: Text('Folder not found.')),
                    );
                  }

                  final subfolders = folderBox.values
                      .where((f) => f.parentId == effectiveFolderId)
                      .map((f) => f.toEntity())
                      .toList();

                  final List<dynamic> files = [];
                  if (filesState is FilesLoadSuccess) {
                    for (var f in filesState.files) {
                      try {
                        final String? fFolderId = (f as dynamic).folderId?.toString();
                        final String? targetFolderId = effectiveFolderId?.toString();
                        if (fFolderId == targetFolderId) {
                          files.add(f);
                        }
                      } catch (_) {}
                    }
                  }

                  final allItems = [...subfolders, ...files];

                  return BlocBuilder<SelectionCubit, SelectionState>(
                    builder: (context, selectionState) {
                      final isSelecting = selectionState.isSelecting;

                      // Clean up selection state if selected items are no longer visible/valid (e.g. deleted/moved/restored)
                      final visibleIds = allItems.map((e) => (e as dynamic).id as String).toSet();
                      final hasInvisibleSelected = selectionState.selectedIds.any((id) => !visibleIds.contains(id));
                      if (hasInvisibleSelected) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            context.read<SelectionCubit>().keepOnly(visibleIds.toList());
                          }
                        });
                      }

                      // Build the body widget based on FilesCubit state
                      final Widget bodyWidget;
                      if (filesState is FilesInitial || filesState is FilesLoadInProgress) {
                        bodyWidget = const Center(child: CircularProgressIndicator());
                      } else if (filesState is FilesLoadFailure) {
                        bodyWidget = Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("0 items", style: TextStyle(fontSize: 11, color: context.subText)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  filesState.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: context.subText),
                                ),
                              ),
                            ),
                            if (!isSelecting) _buildBottomCreateButton(context)
                            else _buildSelectionBottomBar(context, selectionState, []),
                          ],
                        );
                      } else {
                        // FilesLoadSuccess
                        if (allItems.isEmpty && !isSelecting) {
                          bodyWidget = _buildEmptyState(context, isSelecting: isSelecting, state: selectionState, allItems: allItems);
                        } else {
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

                          bodyWidget = Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${allItems.length} items",
                                        style: TextStyle(fontSize: 11, color: context.subText)),
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
                        }
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
                          backgroundColor: context.scaffoldBg,
                          appBar: isSelecting 
                            ? AppBar(
                                backgroundColor: context.primaryColor,
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
                                      final visibleFolders = allItems.whereType<Folder>().toList();
                                      final visibleFiles = allItems.where((item) => item is! Folder).toList();
                                      context.read<SelectionCubit>().selectAll(visibleFolders, visibleFiles);
                                    },
                                    child: const Text("All",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13))),
                                ],
                              )
                            : AppBar(
                                backgroundColor: context.scaffoldBg,
                                elevation: 0,
                                automaticallyImplyLeading: false,
                                title: Row(children: [
                                  InkWell(
                                    onTap: () => context.pop(),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                          color: context.highlightBg,
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.arrow_back, size: 14, color: context.primaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(currentFolderModel?.name ?? 'Root Folder',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: context.primaryText)),
                                ]),
                                actions: [
                                  InkWell(
                                    onTap: () => context.push('/search', extra: {'initialQuery': '', 'folderId': folderId}),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 14),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                          color: context.highlightBg,
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.search, size: 14, color: context.primaryColor),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => context.push('/settings'),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 14),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                          color: context.highlightBg,
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.settings_outlined, size: 14, color: context.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                          body: bodyWidget,
                        ),
                      );
                    },
                  );
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
            Text("0 items", style: TextStyle(fontSize: 11, color: context.subText)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: context.highlightBg,
                  borderRadius: BorderRadius.circular(5)),
              child: Text("Empty",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: context.primaryColor)),
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
                  color: context.highlightBg,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.folder_open_outlined, size: 28, color: context.primaryColor),
            ),
            const SizedBox(height: 14),
            Text("Folder is empty",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.primaryText)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                  "This folder is empty.\nCreate a new note or folder.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: context.subText, height: 1.6)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  context,
                  icon: Icons.note_add_outlined,
                  label: "Note",
                  onTap: () => context.push('/create-note?folderId=${widget.folderId}'),
                ),
                const SizedBox(width: 8),
                _chip(
                  context,
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
            backgroundColor: context.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.border, width: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: context.primaryColor),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(BuildContext context, SelectionState state, List<dynamic> allItems) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.border, width: 0.5))),
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
            icon: Icon(Icons.delete_outline, size: 16, color: context.isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC0392B)),
            label: Text("Delete", style: TextStyle(color: context.isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC0392B))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: context.isDark ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFFFD5D5), width: 0.5),
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
              backgroundColor: context.primaryColor,
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