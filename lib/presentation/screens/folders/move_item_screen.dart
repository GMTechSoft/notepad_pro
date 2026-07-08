import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/data/models/folder_model.dart';
import 'package:notepad_pro/domain/entities/folder.dart';

import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/services/hive_service.dart';

class MoveItemScreen extends StatefulWidget {
  final List<dynamic> itemsToMove;

  const MoveItemScreen({super.key, required this.itemsToMove});

  @override
  State<MoveItemScreen> createState() => _MoveItemScreenState();
}

class _MoveItemScreenState extends State<MoveItemScreen> {
  String _searchQuery = '';
  String? _selectedFolderId;
  bool _isMoving = false;
  late List<FolderModel> _allFolders;
  late Map<String, FolderModel> _folderMap;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() {
    final folderBox = sl<HiveService>().folderBox;
    _allFolders = folderBox.values.toList();
    _folderMap = {for (var f in _allFolders) f.id: f};
  }

  String _buildBreadcrumb(FolderModel folder) {
    List<String> pathNames = [];
    FolderModel? current = folder;
    
    // Prevent infinite loops in case of corrupt data
    int depth = 0; 
    while (current != null && depth < 20) {
      pathNames.insert(0, current.name);
      if (current.parentId == null || current.parentId!.isEmpty) {
        break;
      }
      current = _folderMap[current.parentId];
      depth++;
    }
    
    if (pathNames.isEmpty) return 'Root';
    return pathNames.join(' / ');
  }

  bool _isDescendantOrSelf(String folderId, String targetId) {
    if (folderId == targetId) return true;
    
    FolderModel? current = _folderMap[targetId];
    int depth = 0;
    while (current != null && depth < 20) {
      if (current.parentId == folderId) return true;
      if (current.parentId == null || current.parentId!.isEmpty) return false;
      current = _folderMap[current.parentId];
      depth++;
    }
    return false;
  }

  void _handleSelectTarget(String? targetId) {
    // Validate if any folder is being moved into itself or its descendant
    bool invalidMove = false;
    for (final item in widget.itemsToMove) {
      if (item is Folder || item.runtimeType.toString().contains('Folder')) {
        final folderId = (item as dynamic).id;
        if (targetId != null && _isDescendantOrSelf(folderId, targetId)) {
          invalidMove = true;
          break;
        }
      }
    }

    if (invalidMove) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot move a folder into itself or its own subfolder'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    setState(() {
      _selectedFolderId = targetId;
    });
  }

  Future<void> _executeMove() async {
    if (_selectedFolderId == null && _selectedFolderId != '') {
      return;
    }

    int folderCount = widget.itemsToMove.where((item) => item.runtimeType.toString().contains('Folder')).length;
    int fileCount = widget.itemsToMove.length - folderCount;
    String targetName = _selectedFolderId == null || _selectedFolderId!.isEmpty 
        ? 'Root' 
        : (_folderMap[_selectedFolderId!]?.name ?? 'Unknown');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Selected Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Folders: $folderCount'),
            Text('Files: $fileCount'),
            const SizedBox(height: 12),
            Text('Destination:\n$targetName', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move Here'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isMoving = true;
    });

    final targetId = (_selectedFolderId == null || _selectedFolderId!.isEmpty) ? null : _selectedFolderId;

    try {
      final foldersCubit = context.read<FoldersCubit>();
      final filesCubit = context.read<FilesCubit>();

      for (final item in widget.itemsToMove) {
        final isFolder = item.runtimeType.toString().contains('Folder');
        final itemId = (item as dynamic).id;
        
        if (isFolder) {
          await foldersCubit.moveFolder(folderId: itemId, targetParentId: targetId);
        } else {
          await filesCubit.moveFileToFolder(fileId: itemId, targetFolderId: targetId);
        }
      }
      
      sl<FoldersCubit>().loadFolders();
      sl<FilesCubit>().loadFiles();
      
      if (mounted) {
        context.pop(true); // Return true to indicate success to parent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMoving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move item: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFolders = _allFolders.where((f) {
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    // Sort alphabetically
    filteredFolders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2540)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Move Item',
          style: TextStyle(
            color: Color(0xFF2D2540),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Selected Items Summary
          Container(
            width: double.infinity,
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D2540))),
                const SizedBox(height: 4),
                Text('Folders: ${widget.itemsToMove.where((item) => item.runtimeType.toString().contains('Folder')).length}   Files: ${widget.itemsToMove.where((item) => !item.runtimeType.toString().contains('Folder')).length}', 
                     style: const TextStyle(fontSize: 13, color: Color(0xFF6C5CE7))),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search folders...',
                hintStyle: const TextStyle(color: Color(0xFF9B8DB8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9B8DB8)),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Root Option
                _buildTargetRow(
                  id: '', 
                  name: 'Move to Root Directory', 
                  breadcrumb: 'Main Workspace',
                  icon: Icons.home_outlined,
                  iconColor: const Color(0xFF6C5CE7),
                ),
                
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'ALL FOLDERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9B8DB8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                ...filteredFolders.map((folder) {
                  return _buildTargetRow(
                    id: folder.id,
                    name: folder.name,
                    breadcrumb: _buildBreadcrumb(folder),
                    icon: Icons.folder_outlined,
                    iconColor: const Color(0xFFE5B05C),
                  );
                }),
              ],
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isMoving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE0D9F5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedFolderId == null || _isMoving) ? null : _executeMove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      disabledBackgroundColor: const Color(0xFFEDE9F8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isMoving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Move Here',
                            style: TextStyle(
                              color: _selectedFolderId == null ? const Color(0xFF9B8DB8) : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow({
    required String id,
    required String name,
    required String breadcrumb,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedFolderId == id;
    
    return GestureDetector(
      onTap: () => _handleSelectTarget(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFE0D9F5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2540),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    breadcrumb,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9B8DB8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }
}
