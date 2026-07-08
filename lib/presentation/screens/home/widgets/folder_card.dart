import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
  final int noteCount;
  const FolderCard({super.key, required this.folder, this.noteCount = 0});

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);

    if (today == thatDay) return 'Aaj';
    if (today.subtract(const Duration(days: 1)) == thatDay) return 'Kal';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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

  @override
  Widget build(BuildContext context) {
    final Color stripColor = folder.colorValue != null
        ? Color(folder.colorValue!)
        : const Color(0xFF6C5CE7);
        
    final Color iconBgColor = folder.lightBgColorValue != null
        ? Color(folder.lightBgColorValue!)
        : stripColor.withValues(alpha: 0.1);
        
    final Color iconColor = folder.darkIconColorValue != null
        ? Color(folder.darkIconColorValue!)
        : stripColor;

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
              textDirection: TextDirection.rtl, // Support RTL for Urdu names
              textAlign: TextAlign.left, // Keep layout consistent, title is still on the left generally in ListTile
            ),
            subtitle: Text(
              '$noteCount notes · ${_getRelativeDate(folder.updatedAt)}',
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
  }
}

