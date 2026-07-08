import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/folder.dart' show Folder;
import '../../domain/entities/vault_file.dart';
import '../blocs/files/files_cubit.dart';
import '../blocs/folders/folders_cubit.dart';
import '../blocs/folders/folders_state.dart';
// ... existing imports ...
// Removed top-level breadcrumb helper; use the inner version within the widget.

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

          // Exclude the folder itself when moving a folder.
          final folders = isFolder
              ? state.folders.where((f) => f.id != item.id).toList()
              : state.folders;

          return StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setState) {
              String searchQuery = '';
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
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search folders',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0),
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
                      leading: const Icon(Icons.home_outlined, color: Color(0xFF6C5CE7)),
                      title: const Text(
                        "Root / Home",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      trailing: currentParentId == null ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
                      onTap: () {
                        if (isFolder) {
                          context.read<FoldersCubit>().moveFolder(folderId: item.id, targetParentId: null);
                        } else {
                          context.read<FilesCubit>().moveFileToFolder(fileId: item.id, targetFolderId: null);
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5),
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
                            tileColor: matches ? const Color(0xFFE0F7FA) : null,
                            leading: const Icon(Icons.folder, color: Color(0xFF6C5CE7)),
                            title: Text(folder.name, style: const TextStyle(fontSize: 13)),
                            subtitle: path.isNotEmpty ? Text(path, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                            trailing: isCurrentParent ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
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
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C5CE7))),
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
