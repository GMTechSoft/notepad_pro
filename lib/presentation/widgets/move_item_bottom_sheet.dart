import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

import '../../domain/entities/folder.dart' show Folder;
import '../../domain/entities/vault_file.dart';
import '../blocs/files/files_cubit.dart';
import '../blocs/folders/folders_cubit.dart';
import '../blocs/folders/folders_state.dart';

/// Shows a modal bottom sheet that lets the user move either a [Folder] or a [VaultFile]
/// to a different parent folder. It re‑uses the existing [FoldersCubit] to load the
/// list of folders and calls the appropriate Cubit method based on the type of the
/// item being moved.
void showMoveItemBottomSheet(BuildContext context, {
  required bool isFolder,
  required dynamic item, // Folder or VaultFile
}) {
  // Ensure the latest folders are loaded before displaying the sheet.
  context.read<FoldersCubit>().loadFolders();

  final String? currentParentId = isFolder ? (item as Folder).parentId : (item as VaultFile).folderId;
  String searchQuery = '';

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

          // Exclude the folder itself when moving a folder.
          final folders = isFolder
              ? state.folders.where((f) => f.id != item.id).toList()
              : state.folders;

          return StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setState) {
              // Helper to compute breadcrumb path
              String breadcrumb(Folder folder) {
                List<String> parts = [];
                Folder? current = folder;
                while (current != null && current.parentId != null) {
                  final String parentId = current.parentId!;
                  final Folder? parent = state.folders.firstWhereOrNull((f) => f.id == parentId);
                  if (parent == null) break;
                  parts.insert(0, parent.name);
                  current = parent;
                }
                return parts.join(' / ');
              }

              final filteredFolders = folders.where((f) {
                final query = searchQuery.toLowerCase();
                final nameMatch = f.name.toLowerCase().contains(query);
                final pathMatch = breadcrumb(f).toLowerCase().contains(query);
                return query.isEmpty || nameMatch || pathMatch;
              }).toList();

              final matchHighlightColor = context.isDark ? const Color(0xFF1B3D3C) : const Color(0xFFE0F7FA);

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
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        style: TextStyle(color: context.primaryText, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search folders',
                          hintStyle: TextStyle(color: context.subText, fontSize: 13),
                          prefixIcon: Icon(Icons.search, size: 20, color: context.subText),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: context.highlightBg,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Root / Home option
                    ListTile(
                      leading: Icon(Icons.home_outlined, color: context.primaryColor),
                      title: Text(
                        "Root / Home",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
                      ),
                      trailing: currentParentId == null ? Icon(Icons.check, color: context.primaryColor) : null,
                      onTap: () {
                        if (isFolder) {
                          context.read<FoldersCubit>().moveFolder(folderId: item.id, targetParentId: null);
                        } else {
                          context.read<FilesCubit>().moveFileToFolder(fileId: item.id, targetFolderId: null);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                    Divider(height: 1, thickness: 0.5, color: context.border),
                    // Folder list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredFolders.length,
                        itemBuilder: (context, index) {
                          final folder = filteredFolders[index];
                          final isCurrentParent = currentParentId == folder.id;
                          final path = breadcrumb(folder);
                          final matches = searchQuery.isNotEmpty && (folder.name.toLowerCase().contains(searchQuery.toLowerCase()) || path.toLowerCase().contains(searchQuery.toLowerCase()));
                          return ListTile(
                            tileColor: matches ? matchHighlightColor : null,
                            leading: Icon(Icons.folder, color: context.primaryColor),
                            title: Text(folder.name, style: TextStyle(fontSize: 13, color: context.primaryText)),
                            subtitle: path.isNotEmpty ? Text(path, style: TextStyle(fontSize: 11, color: context.subText)) : null,
                            trailing: isCurrentParent ? Icon(Icons.check, color: context.primaryColor) : null,
                            onTap: isCurrentParent
                                ? null
                                : () {
                                    if (isFolder) {
                                      context.read<FoldersCubit>().moveFolder(folderId: item.id, targetParentId: folder.id);
                                    } else {
                                      context.read<FilesCubit>().moveFileToFolder(fileId: item.id, targetFolderId: folder.id);
                                    }
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
    },
  );
}
