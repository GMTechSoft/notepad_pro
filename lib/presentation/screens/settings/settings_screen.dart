import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_state.dart';
import 'package:notepad_pro/presentation/blocs/theme/theme_cubit.dart';
import 'package:notepad_pro/presentation/screens/settings/about_screen.dart';
import 'package:notepad_pro/presentation/screens/privacy_policy_screen.dart';
import 'package:notepad_pro/core/utils/date_formatter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildCircleButton(
              context,
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 12),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540),
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<SyncCubit, SyncState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              const SizedBox(height: 10),
              _buildSectionLabel("GOOGLE ACCOUNT"),
              const SizedBox(height: 10),
              if (state.status == SyncStatus.signedOut)
                _buildSignedOutCard(context)
              else
                _buildAccountCard(context, state),
              
              if (state.status == SyncStatus.signedOut)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildInfoBanner(
                    "Abhi aapka data sirf is device pe save ho raha hai. Sign in karen to backup aur restore options mil jayen ge.",
                  ),
                ),
              
              if (state.status != SyncStatus.signedOut) ...[
                const SizedBox(height: 24),
                _buildSectionLabel("SYNC SETTINGS"),
                const SizedBox(height: 10),
                _buildSyncSettingsCard(context, state),
              ],

              const SizedBox(height: 24),
              _buildSectionLabel("APP SETTINGS"),
              const SizedBox(height: 10),
              _buildAppSettingsCard(context),
              
              const Padding(
                padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: Column(
                  children: [
                    Text(
                      "Developed by",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B8DB8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "GMTechSoft",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9B8DB8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCircleButton(BuildContext context, {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6C5CE7)),
      ),
    );
  }

  Widget _buildSignedOutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_off_outlined, size: 22, color: Color(0xFF6C5CE7)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Google se connect karein",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
          ),
          const SizedBox(height: 6),
          const Text(
            "Aapka data Google Drive mein safe rahega. Kabhi bhi sync band kar sakte hain.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF9B8DB8), height: 1.5),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.read<SyncCubit>().signIn(),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "G",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Sign in with Google",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, SyncState state) {
    final isPending = state.status == SyncStatus.pending;
    final isError = state.status == SyncStatus.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFF4285F4),
                backgroundImage: state.userPhotoUrl != null && state.userPhotoUrl!.isNotEmpty
                    ? NetworkImage(state.userPhotoUrl!) 
                    : null,
                child: (state.userPhotoUrl == null || state.userPhotoUrl!.isEmpty)
                    ? Text(
                        (state.userName != null && state.userName!.trim().isNotEmpty) 
                            ? state.userName!.trim()[0].toUpperCase() 
                            : ((state.userEmail != null && state.userEmail!.trim().isNotEmpty) 
                                ? state.userEmail!.trim()[0].toUpperCase() 
                                : "U"),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      ) 
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName ?? "User",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                    ),
                    Text(
                      state.userEmail ?? "",
                      style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(state.status),
            ],
          ),
          const SizedBox(height: 12),
          if (isError) ...[
            _buildErrorBanner(state.errorMessage ?? "Sync failed. Please try again."),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFB8C00) : (isError ? Colors.red : const Color(0xFF1D9E75)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isPending 
                  ? "${state.totalFiles - state.driveFiles} files waiting to sync"
                  : (isError ? "Sync Error" : "Last sync: ${_formatDate(state.lastSync)}"),
                style: TextStyle(
                  fontSize: 11, 
                  color: isPending ? const Color(0xFFE65100) : (isError ? Colors.red : const Color(0xFF0F6E56)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(state.totalFiles.toString(), "Total Files")),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatBox(
                  state.driveFiles.toString(), 
                  "Cloud Backup", 
                  textColor: isPending ? const Color(0xFFE65100) : null,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 10),
            _buildWarningBanner(
              "${state.totalFiles - state.driveFiles} files will be automatically uploaded to Drive when connected.",
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cloud_upload_outlined,
                  label: "Backup Now",
                  onPressed: () => context.read<SyncCubit>().syncNow(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cloud_download_outlined,
                  label: "Restore Backup",
                  onPressed: () => _showRestoreConfirmation(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            label: "Sign out",
            isDanger: true,
            onPressed: () => _showSignOutConfirmation(context, state),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAFAFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Data Restore karein?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2540)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Google Drive se aapka purana data download ho kar is device pe save ho jayega. Local data overwrite ho sakta hai.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF9B8DB8), height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<SyncCubit>().restoreNow();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text("Restore Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF0EBF8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(SyncStatus status) {
    final isPending = status == SyncStatus.pending;
    final isError = status == SyncStatus.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF3E0) : (isError ? const Color(0xFFFDECEA) : const Color(0xFFE1F5EE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.access_time : (isError ? Icons.error_outline : Icons.check), 
            size: 10, 
            color: isPending ? const Color(0xFFE65100) : (isError ? Colors.red : const Color(0xFF0F6E56)),
          ),
          const SizedBox(width: 4),
          Text(
            isPending ? "Pending" : (isError ? "Error" : "Synced"),
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w500,
              color: isPending ? const Color(0xFFE65100) : (isError ? Colors.red : const Color(0xFF0F6E56)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.red, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor ?? const Color(0xFF2D2540)),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8))),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFFFF0F0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDanger ? const Color(0xFFF5C0C0) : const Color(0xFFD8D0F0), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isDanger ? const Color(0xFFC0392B) : const Color(0xFF6C5CE7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w500, 
                color: isDanger ? const Color(0xFFC0392B) : const Color(0xFF6C5CE7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsCard(BuildContext context, SyncState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            icon: Icons.wifi,
            title: "Auto sync",
            subtitle: "Har note save hone pe drive update ho",
            value: state.autoSync,
            onChanged: (val) => context.read<SyncCubit>().toggleAutoSync(val),
          ),
          const Divider(height: 1, color: Color(0xFFE0D9F5), thickness: 0.5),
          _buildToggleRow(
            icon: Icons.wifi_off_outlined,
            title: "Offline notes sync on connect",
            subtitle: "Internet aane pe pending notes upload hon",
            value: state.offlineSync,
            onChanged: (val) => context.read<SyncCubit>().toggleOfflineSync(val),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Column(
        children: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeState) {
              final isDarkMode = themeState == ThemeMode.dark;
              return _buildToggleRow(
                icon: Icons.brightness_6_outlined,
                title: "Dark Mode",
                subtitle: "App ki theme badlein",
                value: isDarkMode,
                onChanged: (val) => context.read<ThemeCubit>().toggleTheme(val),
                iconBg: const Color(0xFFEDE9F8),
                iconColor: const Color(0xFF6C5CE7),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFE0D9F5), thickness: 0.5),
          _buildListRow(
            icon: Icons.info_outline,
            title: "About Notepad Pro",
            subtitle: "Version 1.0.0 · Help guide",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
          ),
          const Divider(height: 1, color: Color(0xFFE0D9F5), thickness: 0.5),
          _buildListRow(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Data protection policy",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    Color iconBg = const Color(0xFFE1F5EE),
    Color iconColor = const Color(0xFF0F6E56),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6C5CE7),
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildListRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF6C5CE7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFC4B8E0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F8),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF6C5CE7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF854F0B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context, SyncState state) {
    final pendingCount = state.totalFiles - state.driveFiles;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAFAFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sign out karein?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2540)),
                ),
                const SizedBox(height: 12),
                Text(
                  pendingCount > 0 
                    ? "Aapke $pendingCount local files hain jo Drive mein nahi hain. Sign out karne se ye files sirf is device pe rahen ge."
                    : "Kya aap waqai sign out karna chahte hain?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9B8DB8), height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<SyncCubit>().signOut();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text("Sign out anyway", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF0EBF8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    
    final dayString = DateFormatter.getFormattedDate(date);
    final timeString = DateFormat('h:mm a').format(date);
    
    if (dayString == "Today") {
      return timeString;
    }
    
    return "$dayString, $timeString";
  }
}
