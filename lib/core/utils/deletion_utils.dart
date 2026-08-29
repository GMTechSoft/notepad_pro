import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/files/files_cubit.dart';
import '../../presentation/blocs/folders/folders_cubit.dart';
import '../../presentation/blocs/selection/selection_cubit.dart';

class DeletionUtils {
  static void showUnifiedDeleteDialog(BuildContext context, {required List<dynamic> items}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(items.length == 1 ? 'Delete File' : 'Delete Items'),
        content: Text(items.length == 1 
            ? 'Where do you want to delete this file?' 
            : 'Where do you want to delete the selected items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting from this device only...')),
                );
              }
              for (final item in items) {
                final typeStr = item.runtimeType.toString();
                if (typeStr.contains('Folder')) {
                  await context.read<FoldersCubit>().deleteFolder((item as dynamic).id);
                } else if (typeStr.contains('VaultFile')) {
                  await context.read<FilesCubit>().deleteFile((item as dynamic).id, deleteFromCloud: false);
                }
              }
              if (context.mounted) {
                context.read<SelectionCubit>().clearSelection();
                context.read<FoldersCubit>().loadFolders();
                context.read<FilesCubit>().loadFiles();
              }
            },
            child: const Text('Delete from this device'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting from device and backup...')),
                );
              }
              
              bool allCloudSuccess = true;
              
              for (final item in items) {
                final typeStr = item.runtimeType.toString();
                if (typeStr.contains('Folder')) {
                  await context.read<FoldersCubit>().deleteFolder((item as dynamic).id);
                } else if (typeStr.contains('VaultFile')) {
                  final success = await context.read<FilesCubit>().deleteFile((item as dynamic).id, deleteFromCloud: true);
                  if (success == false) allCloudSuccess = false;
                }
              }
              
              if (context.mounted) {
                context.read<SelectionCubit>().clearSelection();
                context.read<FoldersCubit>().loadFolders();
                context.read<FilesCubit>().loadFiles();
                
                if (!allCloudSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Some cloud deletions failed or are pending (offline).'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted successfully from device and backup.')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete from device & backup'),
          ),
        ],
      ),
    );
  }
}
