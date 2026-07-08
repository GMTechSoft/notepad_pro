import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';
import 'package:notepad_pro/core/utils/date_formatter.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
  const FolderCard({super.key, required this.folder});

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('Are you sure you want to delete this folder? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<FoldersCubit>().deleteFolder(folder.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await showCreateFolderDialog(
      context,
      initialName: folder.name,
      initialColorValue: folder.colorValue,
      initialLightBgColorValue: folder.lightBgColorValue,
      initialDarkIconColorValue: folder.darkIconColorValue,
    );

    if (result != null && result['name'] != null && (result['name'] as String).isNotEmpty) {
      if (!context.mounted) return;
      final updatedFolder = folder.copyWith(
        name: result['name'] as String,
        colorValue: result['colorValue'] as int?,
        lightBgColorValue: result['lightBgColorValue'] as int?,
        darkIconColorValue: result['darkIconColorValue'] as int?,
        updatedAt: DateTime.now(),
      );
      context.read<FoldersCubit>().updateFolder(updatedFolder);
    }
  }

  int _getImmediateFolderItemsCount(String folderId, List<Folder> allFolders, List<VaultFile> allFiles) {
    final int directFiles = allFiles.where((file) => file.folderId == folderId).length;
    final int directSubFolders = allFolders.where((f) => f.parentId == folderId).length;
    return directFiles + directSubFolders;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoldersCubit, FoldersState>(
      builder: (context, foldersState) {
        return BlocBuilder<FilesCubit, FilesState>(
          builder: (context, filesState) {
            final Color stripColor = folder.colorValue != null
                ? Color(folder.colorValue!)
                : const Color(0xFF6C5CE7);
                
            final Color iconBgColor = folder.lightBgColorValue != null
                ? Color(folder.lightBgColorValue!)
                : stripColor.withValues(alpha: 0.1);
                
            final Color iconColor = folder.darkIconColorValue != null
                ? Color(folder.darkIconColorValue!)
                : stripColor;

            int totalItems = 0;
            if (foldersState is FoldersLoadSuccess && filesState is FilesLoadSuccess) {
              totalItems = _getImmediateFolderItemsCount(folder.id, foldersState.folders, filesState.files);
            }

            final String itemString = totalItems == 1 ? "1 Item" : "$totalItems Items";

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Left Side Strip
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: stripColor,
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder_rounded, 
                        size: 20, 
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      folder.name, 
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF2D2540),
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.left,
                    ),
                    subtitle: Text(
                      '$itemString · ${DateFormatter.getFormattedDate(folder.updatedAt)}',
                      style: const TextStyle(
                        color: Color(0xFF9B8DB8),
                        fontSize: 10,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFFC4B8E0)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(context);
                        } else if (value == 'delete') {
                          _showDeleteDialog(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await context.push('/folder/${folder.id}');
                      if (context.mounted) {
                        context.read<FoldersCubit>().loadFolders();
                        context.read<FilesCubit>().loadFiles();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

