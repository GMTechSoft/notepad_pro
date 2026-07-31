import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

/// Shows a modal bottom sheet that lets the user move a [VaultFile] to a different folder.
/// This function is defined as a top‑level helper so it can be called from any widget
/// (e.g., `FileCard` or `FolderCard`). It loads the list of folders via the
/// [FoldersCubit] and then calls [FilesCubit.moveFileToFolder] when a target is
/// selected.
void showMoveNoteBottomSheet(BuildContext context, VaultFile currentFile) {
  // Ensure the latest folders are loaded before displaying the sheet.
  context.read<FoldersCubit>().loadFolders();

  showModalBottomSheet(
    context: context,
    backgroundColor: context.scaffoldBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return BlocBuilder<FoldersCubit, FoldersState>(
        builder: (context, state) {
          if (state is! FoldersLoadSuccess) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(context.primaryColor)));
          }

          final folders = state.folders;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 9, bottom: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                Text(
                  "SELECT TARGET FOLDER",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.subText),
                ),
                const SizedBox(height: 8),
                // Root / Home option
                ListTile(
                  leading: Icon(Icons.home_outlined, color: context.primaryColor),
                  title: Text(
                    "Root / Home",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
                  ),
                  trailing: currentFile.folderId == null ? Icon(Icons.check, color: context.primaryColor) : null,
                  onTap: () {
                    context.read<FilesCubit>().moveFileToFolder(fileId: currentFile.id, targetFolderId: null);
                    Navigator.pop(ctx);
                  },
                ),
                Divider(height: 1, thickness: 0.5, color: context.border),
                // Folder list
                Expanded(
                  child: ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final isCurrentFolder = currentFile.folderId == folder.id;
                      return ListTile(
                        leading: Icon(Icons.folder, color: context.primaryColor),
                        title: Text(folder.name, style: TextStyle(fontSize: 13, color: context.primaryText)),
                        trailing: isCurrentFolder ? Icon(Icons.check, color: context.primaryColor) : null,
                        onTap: isCurrentFolder
                            ? null
                            : () {
                                context.read<FilesCubit>().moveFileToFolder(fileId: currentFile.id, targetFolderId: folder.id);
                                Navigator.pop(ctx);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: context.primaryColor)),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
