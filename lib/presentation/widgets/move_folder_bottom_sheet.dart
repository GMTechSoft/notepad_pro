import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';

/// Shows a modal bottom sheet that lets the user move a [Folder] to a different parent folder.
/// It uses the [FoldersCubit] to load folders and calls [FoldersCubit.moveFolder] when a target is selected.
void showMoveFolderBottomSheet(BuildContext context, Folder currentFolder) {
  // Ensure the latest folders are loaded before displaying the sheet.
  context.read<FoldersCubit>().loadFolders();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFFFAFAFF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return BlocBuilder<FoldersCubit, FoldersState>(
        builder: (context, state) {
          if (state is! FoldersLoadSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = state.folders.where((f) => f.id != currentFolder.id).toList();
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 9, bottom: 8),
                  width: 32,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD0C8E8),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const Text(
                  "SELECT TARGET FOLDER",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9B8DB8)),
                ),
                const SizedBox(height: 8),
                // Root / Home option
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Color(0xFF6C5CE7)),
                  title: const Text(
                    "Root / Home",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  trailing: currentFolder.parentId == null ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
                  onTap: () {
                    context.read<FoldersCubit>().moveFolder(folderId: currentFolder.id, targetParentId: null);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1, thickness: 0.5),
                // Folder list
                Expanded(
                  child: ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final isCurrentParent = currentFolder.parentId == folder.id;
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Color(0xFF6C5CE7)),
                        title: Text(folder.name, style: const TextStyle(fontSize: 13)),
                        trailing: isCurrentParent ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
                        onTap: isCurrentParent
                            ? null
                            : () {
                                context.read<FoldersCubit>().moveFolder(folderId: currentFolder.id, targetParentId: folder.id);
                                Navigator.pop(ctx);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C5CE7))),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
