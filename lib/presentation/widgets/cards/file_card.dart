import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/selection/selection_cubit.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/deletion_utils.dart';

class FileCard extends StatelessWidget {
  final VaultFile file;
  const FileCard({super.key, required this.file});

  void _showDeleteDialog(BuildContext context) {
    DeletionUtils.showUnifiedDeleteDialog(context, items: [file]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color fileColor = Color(0xFF0F6E56); // Teal for files
    final isSelected = context.select<SelectionCubit, bool>((cubit) => cubit.state.selectedMap.containsKey(file.id));
    final isSelectionMode = context.select<SelectionCubit, bool>((cubit) => cubit.state.isSelectionMode);

    final Widget card = GestureDetector(
      onLongPress: () => context.read<SelectionCubit>().toggleSelection(file.id, false),
      onTap: () {
        if (isSelectionMode) {
          context.read<SelectionCubit>().toggleSelection(file.id, false);
        } else {
          context.push('/read-note', extra: {'file': file, 'highlightQuery': null});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, 
            width: isSelected ? 1.5 : 0.5
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left Side Strip
            if (!isSelected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: fileColor,
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined, 
                  size: 20, 
                  color: fileColor,
                ),
              ),
              title: Text(
                file.title, 
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${file.description.isEmpty ? "No description" : file.description} · ${DateFormatter.getFormattedDate(file.updatedAt)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isSelected 
                ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 22)
                : (isSelectionMode ? null : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
                onSelected: (value) {
                  if (value == 'edit') {
                      context.push('/create-file', extra: file);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    } else if (value == 'move') {
                      context.push('/move-item', extra: [file]);
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
                  PopupMenuItem(
                    value: 'move',
                    child: ListTile(
                      leading: Icon(Icons.drive_file_move_outline, color: theme.colorScheme.primary),
                      title: const Text('Move'),
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
              )),
            ),
          ],
        ),
      ),
    );
    
    return SizedBox(
      width: double.infinity,
      child: card,
    );
  }
}
