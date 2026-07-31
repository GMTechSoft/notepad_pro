import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_state.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

/// Shows a modal bottom sheet that lets the user move a [Folder] to a different parent folder.
/// It uses the [FoldersCubit] to load folders and calls [FoldersCubit.moveFolder] when a target is selected.
void showMoveFolderBottomSheet(BuildContext context, Folder currentFolder) {
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
                  trailing: currentFolder.parentId == null ? Icon(Icons.check, color: context.primaryColor) : null,
                  onTap: () {
                    context.read<FoldersCubit>().moveFolder(folderId: currentFolder.id, targetParentId: null);
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
                      final isCurrentParent = currentFolder.parentId == folder.id;
                      return ListTile(
                        leading: Icon(Icons.folder, color: context.primaryColor),
                        title: Text(folder.name, style: TextStyle(fontSize: 13, color: context.primaryText)),
                        trailing: isCurrentParent ? Icon(Icons.check, color: context.primaryColor) : null,
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
