import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/domain/entities/folder.dart';
import 'package:notepad_pro/services/hive_service.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/data/models/vault_file_model.dart';
import 'package:notepad_pro/data/models/note_model.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/create_bottom_sheet.dart';
import 'package:notepad_pro/presentation/widgets/cards/folder_card.dart';
import 'package:notepad_pro/presentation/widgets/cards/file_card.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/empty_vault_view.dart';
import 'package:notepad_pro/presentation/widgets/app_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = sl<HiveService>();

    return ValueListenableBuilder(
      valueListenable: hiveService.folderBox.listenable(),
      builder: (context, Box<FolderModel> folderBox, _) {
        return ValueListenableBuilder(
          valueListenable: hiveService.fileBox.listenable(),
          builder: (context, Box<VaultFileModel> fileBox, _) {
            return ValueListenableBuilder(
              valueListenable: hiveService.noteBox.listenable(),
              builder: (context, Box<NoteModel> noteBox, _) {
                // Filter and sort items
                final rootFolders = folderBox.values
                    .where((f) => f.parentId == null || f.parentId == '')
                    .map((f) => f.toEntity())
                    .toList();

                final rootFiles = fileBox.values
                    .where((f) => f.folderId == null || f.folderId == '')
                    .map((f) => f.toEntity())
                    .toList();

                // Also include root notes in the main list
                final rootNotes = noteBox.values
                    .where((n) => n.folderId == null || n.folderId == '')
                    .map((n) => n.toEntity())
                    .toList();

                final allItems = [...rootFolders, ...rootFiles, ...rootNotes];

                allItems.sort((a, b) {
                  final isAFolder = a.runtimeType.toString().contains('Folder');
                  final isBFolder = b.runtimeType.toString().contains('Folder');
                  if (isAFolder && !isBFolder) return -1;
                  if (!isAFolder && isBFolder) return 1;

                  // Extract names safely
                  String nameA = '';
                  if (isAFolder) {
                    nameA = (a as dynamic).name;
                  } else if (a.runtimeType.toString().contains('VaultFile')) {
                    nameA = (a as dynamic).title;
                  } else {
                    nameA = (a as dynamic).title;
                  }

                  String nameB = '';
                  if (isBFolder) {
                    nameB = (b as dynamic).name;
                  } else if (b.runtimeType.toString().contains('VaultFile')) {
                    nameB = (b as dynamic).title;
                  } else {
                    nameB = (b as dynamic).title;
                  }

                  return nameA.compareTo(nameB);
                });

                if (allItems.isEmpty) {
                  return const EmptyVaultView();
                }

                return Scaffold(
                  backgroundColor: const Color(0xFFF5F0FF),
                  body: SafeArea(
                    child: Column(
                      children: [
                        // Custom Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const AppLogo(size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'My Notes Vault',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D2540),
                                ),
                              ),
                              const Spacer(),
                              _buildHeaderButton(
                                icon: Icons.search,
                                onPressed: () => context.push('/search'),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderButton(
                                icon: Icons.settings_outlined,
                                onPressed: () => context.push('/settings'),
                              ),
                            ],
                          ),
                        ),

                        // List Header Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${rootFolders.length} folders',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9B8DB8),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9F8),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.sort,
                                        size: 12, color: Color(0xFF6C5CE7)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Recent',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6C5CE7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              if (item is Folder) {
                                return FolderCard(
                                  folder: item,
                                );
                              } else if (item.runtimeType
                                  .toString()
                                  .contains('VaultFile')) {
                                return FileCard(file: item as dynamic);
                              } else {
                                // Fallback or legacy
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),

                        // Bottom CTA
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => showCreateBottomSheet(context),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Create new',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6C5CE7)),
      ),
    );
  }
}
