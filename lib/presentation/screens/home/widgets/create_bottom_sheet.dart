import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';

void showCreateBottomSheet(BuildContext context, {String? parentFolderId}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final folderIconBg = theme.colorScheme.primaryContainer;
  final folderIconColor = theme.colorScheme.primary;

  final noteIconBg = isDark ? const Color(0xFF1B3D32) : const Color(0xFFE1F5EE);
  final noteIconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF0F6E56);

  showModalBottomSheet(
    context: context,
    backgroundColor: theme.scaffoldBackgroundColor,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: theme.colorScheme.outline, width: 0.5),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Section Title
              Text(
                'CREATE NEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.05 * 11, // letter-spacing 0.05em
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              
              // Option 1: Folder
              _buildOptionCard(
                context,
                icon: Icons.create_new_folder_outlined,
                iconColor: folderIconColor,
                iconBg: folderIconBg,
                title: 'Folder',
                subtitle: 'Group your notes together',
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await showCreateFolderDialog(context);
                  if (result != null && result['name'] != null && (result['name'] as String).isNotEmpty) {
                    if (!context.mounted) return;
                    await context.read<FoldersCubit>().createFolder(
                          result['name'] as String,
                          parentFolderId,
                          result['colorValue'] as int?,
                          lightBgColorValue: result['lightBgColorValue'] as int?,
                          darkIconColorValue: result['darkIconColorValue'] as int?,
                        );
                  }
                },
              ),
              
              const SizedBox(height: 10),
              
              // Option 2: Note / File
              _buildOptionCard(
                context,
                icon: Icons.note_add_outlined,
                iconColor: noteIconColor,
                iconBg: noteIconBg,
                title: 'Note / File',
                subtitle: 'Write something new',
                onTap: () {
                  Navigator.pop(ctx);
                  String path = '/create-file';
                  if (parentFolderId != null) {
                    path = '$path?folderId=$parentFolderId';
                  }
                  context.push(path);
                },
              ),
              
              const SizedBox(height: 10),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOptionCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: Row(
        children: [
          // Icon Tile
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          
          // Text Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Chevron Right
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline,
            size: 20,
          ),
        ],
      ),
    ),
  );
}
