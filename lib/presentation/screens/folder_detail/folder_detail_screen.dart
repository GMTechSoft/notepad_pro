import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/presentation/widgets/cards/file_card.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/create_bottom_sheet.dart';
import 'package:notepad_pro/presentation/widgets/cards/folder_card.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';

class FolderDetailScreen extends StatelessWidget {
  final String folderId;
  const FolderDetailScreen({super.key, required this.folderId});

  void _showCreateOptions(BuildContext context) {
    showCreateBottomSheet(context, parentFolderId: folderId);
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = sl<HiveService>();

    return ValueListenableBuilder(
      valueListenable: hiveService.folderBox.listenable(),
      builder: (context, Box<FolderModel> folderBox, _) {
        final currentFolderModel = folderBox.get(folderId);

        if (currentFolderModel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Folder not found.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F0FF),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(children: [
              InkWell(
                onTap: () => context.pop(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEDE9F8),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_back,
                      size: 14, color: Color(0xFF6C5CE7)),
                ),
              ),
              const SizedBox(width: 8),
              Text(currentFolderModel.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D2540))),
            ]),
            actions: [
              InkWell(
                onTap: () => context.push('/search'),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEDE9F8),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.search,
                      size: 14, color: Color(0xFF6C5CE7)),
                ),
              ),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: hiveService.fileBox.listenable(),
            builder: (context, Box<VaultFileModel> fileBox, _) {
              return ValueListenableBuilder(
                valueListenable: hiveService.noteBox.listenable(),
                builder: (context, Box<NoteModel> noteBox, _) {
                  final subfolders = folderBox.values
                      .where((f) => f.parentId == folderId)
                      .map((f) => f.toEntity())
                      .toList();

                  final files = fileBox.values
                      .where((f) => f.folderId == folderId)
                      .map((f) => f.toEntity())
                      .toList();

                  final notes = noteBox.values
                      .where((n) => n.folderId == folderId)
                      .map((n) => n.toEntity())
                      .toList();

                  final allItems = [...subfolders, ...files, ...notes];

                  if (allItems.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Sort folders first, then files/notes, alphabetically
                  allItems.sort((a, b) {
                    final isAFolder =
                        a.runtimeType.toString().contains('Folder');
                    final isBFolder =
                        b.runtimeType.toString().contains('Folder');
                    if (isAFolder && !isBFolder) return -1;
                    if (!isAFolder && isBFolder) return 1;

                    final nameA =
                        isAFolder ? (a as dynamic).name : (a as dynamic).title;
                    final nameB =
                        isBFolder ? (b as dynamic).name : (b as dynamic).title;
                    return (nameA as String).compareTo(nameB as String);
                  });

                  return Column(
                    children: [
                      // Meta bar for populated list
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${allItems.length} items",
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9B8DB8))),
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
                            } else if (item.runtimeType
                                .toString()
                                .contains('VaultFile')) {
                              return FileCard(file: item as dynamic);
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      // Bottom Create button
                      _buildBottomCreateButton(context),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(children: [
      // Meta bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("0 items",
                style: TextStyle(fontSize: 11, color: Color(0xFF9B8DB8))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text("Empty",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C5CE7))),
            ),
          ],
        ),
      ),

      // Empty state — centered
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Folder open icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.folder_open_outlined,
                  size: 28, color: Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 14),

            // Title
            const Text("Folder khali hai",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540))),
            const SizedBox(height: 6),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                  "Is folder mein abhi kuch nahi.\nNaya note ya folder banayein.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF9B8DB8), height: 1.6)),
            ),
            const SizedBox(height: 20),

            // Action chips row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  icon: Icons.note_add_outlined,
                  label: "Note",
                  onTap: () => context.push('/create-note?folderId=$folderId'),
                ),
                const SizedBox(width: 8),
                _chip(
                  icon: Icons.create_new_folder_outlined,
                  label: "Sub-folder",
                  onTap: () async {
                    final result = await showCreateFolderDialog(context);
                    if (result != null && result['name'] != null && (result['name'] as String).isNotEmpty) {
                      if (!context.mounted) return;
                      await context.read<FoldersCubit>().createFolder(
                            result['name'] as String,
                            folderId,
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

      // Create new button
      _buildBottomCreateButton(context),
    ]);
  }

  Widget _buildBottomCreateButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16,
          MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Create new",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6C5CE7)),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6C5CE7))),
          ],
        ),
      ),
    );
  }
}
