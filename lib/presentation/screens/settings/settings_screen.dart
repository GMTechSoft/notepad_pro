import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_state.dart';
import 'package:notepad_pro/presentation/screens/settings/about_screen.dart';
import 'package:notepad_pro/presentation/screens/privacy_policy_screen.dart';
import 'package:notepad_pro/core/utils/date_formatter.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
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
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.primaryText,
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
              _buildSectionLabel(context, "GOOGLE ACCOUNT"),
              const SizedBox(height: 10),
              if (state.status == SyncStatus.signedOut)
                _buildSignedOutCard(context)
              else
                _buildAccountCard(context, state),
              
              if (state.status == SyncStatus.signedOut)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildInfoBanner(
                    context,
                    "Your data is currently stored only on this device. Sign in to enable backup and restore options.",
                  ),
                ),
              
              if (state.status != SyncStatus.signedOut) ...[
                const SizedBox(height: 24),
                _buildSectionLabel(context, "SYNC SETTINGS"),
                const SizedBox(height: 10),
                _buildSyncSettingsCard(context, state),
              ],

              const SizedBox(height: 24),
              _buildSectionLabel(context, "APP SETTINGS"),
              const SizedBox(height: 10),
              _buildAppSettingsCard(context),
              
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: Column(
                  children: [
                    Text(
                      "Developed by",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: context.subText,
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
          color: context.highlightBg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: context.primaryColor),
      ),
    );
  }

  Widget _buildSignedOutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.highlightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.cloud_off_outlined, size: 22, color: context.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            "Sign in with Google",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
          ),
          const SizedBox(height: 6),
          Text(
            "Your data will be securely backed up to Google Drive. You can turn off synchronization at any time.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: context.subText, height: 1.5),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.read<SyncCubit>().signIn(),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: context.border, width: 0.5),
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
                  Text(
                    "Sign in with Google",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
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
    final isError = state.status == SyncStatus.error;
    
    String getUploadMessage(int count) {
      if (count == 0) {
        return "0 files waiting.";
      } else if (count == 1) {
        return "1 file will be automatically uploaded.";
      } else {
        return "$count files will be automatically uploaded.";
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
                    ),
                    Text(
                      state.userEmail ?? "",
                      style: TextStyle(fontSize: 10, color: context.subText),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, state.status),
            ],
          ),
          const SizedBox(height: 12),
          if (state.status == SyncStatus.offline) ...[
            _buildOfflineBanner(context, "You're offline. Changes have been saved locally."),
            const SizedBox(height: 12),
          ] else if (isError) ...[
            _buildErrorBanner(context, _getFriendlyErrorMessage(state.errorMessage)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: state.status == SyncStatus.pending
                      ? const Color(0xFFFB8C00)
                      : (state.status == SyncStatus.error
                          ? Colors.red
                          : (state.status == SyncStatus.offline
                              ? Colors.grey
                              : (state.status == SyncStatus.syncing
                                  ? Colors.blue
                                  : const Color(0xFF1D9E75)))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.status == SyncStatus.syncing
                  ? "Syncing files..."
                  : (state.status == SyncStatus.offline
                      ? ((state.autoSync && state.offlineSync)
                          ? "Your changes will sync automatically when you're back online."
                          : "Your changes are saved locally. Tap 'Backup Now' to sync.")
                      : (state.status == SyncStatus.error
                          ? "Sync Error: ${_getFriendlyErrorMessage(state.errorMessage)}"
                          : (state.pendingFiles > 0
                              ? "${state.pendingFiles} file${state.pendingFiles == 1 ? '' : 's'} waiting to sync"
                              : "Last sync: ${_formatDate(state.lastSync)}"))),
                style: TextStyle(
                  fontSize: 11, 
                  color: state.status == SyncStatus.offline
                    ? (context.isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100))
                    : (state.status == SyncStatus.pending 
                        ? (context.isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)) 
                        : (state.status == SyncStatus.error ? (context.isDark ? const Color(0xFFEF9A9A) : Colors.red) : (context.isDark ? const Color(0xFF81C784) : const Color(0xFF0F6E56)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(context, state.totalFiles.toString(), "Total Files")),
              const SizedBox(width: 6),
              Expanded(child: _buildStatBox(context, state.driveFiles.toString(), "Cloud Backup")),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  state.pendingFiles.toString(),
                  "Pending Files",
                  textColor: state.pendingFiles > 0
                      ? (context.isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100))
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatBox(
                  context,
                  state.lastSync != null ? _formatDate(state.lastSync) : "Never",
                  "Last Backup",
                ),
              ),
            ],
          ),
          if (state.pendingFiles > 0) ...[
            const SizedBox(height: 10),
            _buildWarningBanner(
              context,
              getUploadMessage(state.pendingFiles),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.cloud_upload_outlined,
                  label: "Backup Now",
                  onPressed: () => context.read<SyncCubit>().syncNow(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.cloud_download_outlined,
                  label: "Restore Backup",
                  onPressed: () => _showRestoreConfirmation(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
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
      backgroundColor: context.scaffoldBg,
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
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Restore Data?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your backup data will be downloaded from Google Drive and saved on this device. Local data may be overwritten.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.subText, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final syncCubit = context.read<SyncCubit>();
                      Navigator.pop(ctx);
                      await syncCubit.restoreNow(context: context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
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
                      backgroundColor: context.highlightBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text("Cancel", style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500)),
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

  Widget _buildStatusBadge(BuildContext context, SyncStatus status) {
    String label;
    IconData icon;
    Color bgColor;
    Color fgColor;

    final isDark = context.isDark;

    switch (status) {
      case SyncStatus.signedOut:
        label = "Authentication Required";
        icon = Icons.error_outline;
        bgColor = isDark ? const Color(0xFF4A2828) : const Color(0xFFFDECEA);
        fgColor = isDark ? const Color(0xFFEF9A9A) : Colors.red;
        break;
      case SyncStatus.offline:
        label = "Offline";
        icon = Icons.cloud_off;
        bgColor = isDark ? const Color(0xFF37474F) : const Color(0xFFECEFF1);
        fgColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF455A64);
        break;
      case SyncStatus.syncing:
        label = "Syncing...";
        icon = Icons.sync;
        bgColor = isDark ? const Color(0xFF233B4A) : const Color(0xFFE3F2FD);
        fgColor = isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
        break;
      case SyncStatus.error:
        label = "Backup Failed";
        icon = Icons.error_outline;
        bgColor = isDark ? const Color(0xFF4A2828) : const Color(0xFFFDECEA);
        fgColor = isDark ? const Color(0xFFEF9A9A) : Colors.red;
        break;
      case SyncStatus.pending:
        label = "Pending";
        icon = Icons.access_time;
        bgColor = isDark ? const Color(0xFF4E3629) : const Color(0xFFFFF3E0);
        fgColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
        break;
      case SyncStatus.connected:
        label = "Connected";
        icon = Icons.check;
        bgColor = isDark ? const Color(0xFF1B3D32) : const Color(0xFFE1F5EE);
        fgColor = isDark ? const Color(0xFF81C784) : const Color(0xFF0F6E56);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w500,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF4A2828) : const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 0.5),
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

  Widget _buildOfflineBanner(BuildContext context, String text) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2E3B) : const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.blueGrey[200] : Colors.blueGrey[800], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getFriendlyErrorMessage(String? msg) {
    if (msg == null) return "Sync failed. Please try again.";
    final lower = msg.toLowerCase();
    if (lower.contains("socketexception") || 
        lower.contains("host lookup") || 
        lower.contains("connection") || 
        lower.contains("offline") || 
        lower.contains("network") ||
        lower.contains("clientexception")) {
      return "Network connection issue. Please check your internet connection and try again.";
    }
    return msg;
  }

  Widget _buildStatBox(BuildContext context, String value, String label, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor ?? context.primaryText),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: context.subText)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
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
          color: isDanger 
            ? (context.isDark ? const Color(0xFF5A2A2A) : const Color(0xFFFFF0F0)) 
            : context.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDanger 
              ? (context.isDark ? Colors.red.withValues(alpha: 0.5) : const Color(0xFFF5C0C0)) 
              : context.border, 
            width: 0.5
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 14, 
              color: isDanger 
                ? (context.isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC0392B)) 
                : context.primaryColor
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w500, 
                color: isDanger 
                  ? (context.isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC0392B)) 
                  : context.primaryColor,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            context,
            icon: Icons.wifi,
            title: "Auto sync",
            subtitle: "Automatically sync notes to Google Drive",
            value: state.autoSync,
            onChanged: (val) => context.read<SyncCubit>().toggleAutoSync(val),
          ),
          Divider(height: 1, color: context.border, thickness: 0.5),
          _buildToggleRow(
            context,
            icon: Icons.wifi_off_outlined,
            title: "Offline notes sync on connect",
            subtitle: "Automatically upload pending notes when you're back online.",
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version;
              final verText = (version != null && version.isNotEmpty)
                  ? "Version $version"
                  : "Version Unknown";
              return _buildListRow(
                context,
                icon: Icons.info_outline,
                title: "About NotePilot",
                subtitle: "$verText · Help guide",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen())),
              );
            },
          ),
          Divider(height: 1, color: context.border, thickness: 0.5),
          _buildListRow(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Data protection policy",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    Color? iconBg,
    Color? iconColor,
  }) {
    final defaultIconBg = iconBg ?? (context.isDark ? const Color(0xFF1B3D32) : const Color(0xFFE1F5EE));
    final defaultIconColor = iconColor ?? (context.isDark ? const Color(0xFF81C784) : const Color(0xFF0F6E56));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: defaultIconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: defaultIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: context.subText),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: context.primaryColor,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(
    BuildContext context, {
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
                color: context.highlightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: context.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: context.subText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: context.border),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.highlightBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: context.isDark ? const Color(0xFFBBADFF) : const Color(0xFF534AB7), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF4E3629) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 16, color: context.isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: context.isDark ? const Color(0xFFFFB74D) : const Color(0xFF854F0B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context, SyncState state) {
    final pendingCount = state.pendingFiles;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBg,
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
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Sign out?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryText),
                ),
                const SizedBox(height: 12),
                Text(
                  pendingCount > 0 
                    ? "You have $pendingCount local files that are not backed up. Signing out will keep these files only on this device."
                    : "Are you sure you want to sign out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.subText, height: 1.5),
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
                      backgroundColor: context.highlightBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text("Cancel", style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500)),
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
