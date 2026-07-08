import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/presentation/blocs/folders/folders_cubit.dart';
import 'package:notepad_pro/presentation/screens/home/widgets/create_bottom_sheet.dart';
import 'package:notepad_pro/presentation/widgets/create_folder_dialog.dart';

import 'vault_search_delegate.dart';
class EmptyVaultView extends StatelessWidget {
  const EmptyVaultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildCenterContent(),
            ),
            _buildActionChips(context),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'NotePilot App',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => showSearch(
              context: context,
              delegate: VaultSearchDelegate(),
            ),
            child: _buildHeaderButton(Icons.search),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: _buildHeaderButton(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF6C5CE7),
        size: 20,
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9F8),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.book_outlined,
            color: Color(0xFF6C5CE7),
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your vault is empty',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D2540),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Create your first note or folder. Everything stays private, right here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9B8DB8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChip(context, 'Note', Icons.description_outlined, () => context.push('/create-note')),
          const SizedBox(width: 12),
          _buildChip(context, 'Folder', Icons.folder_outlined, () async {
            final result = await showCreateFolderDialog(context);
            if (result != null && result['name'] != null && (result['name'] as String).isNotEmpty) {
              if (!context.mounted) return;
              await context.read<FoldersCubit>().createFolder(
                    result['name'] as String,
                    null,
                    result['colorValue'] as int?,
                    lightBgColorValue: result['lightBgColorValue'] as int?,
                    darkIconColorValue: result['darkIconColorValue'] as int?,
                  );
            }
          }),
          const SizedBox(width: 12),
          _buildChip(context, 'Secret note', Icons.lock_outline, () => context.push('/create-note')),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF6C5CE7), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => showCreateBottomSheet(context),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),

            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Create new',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
