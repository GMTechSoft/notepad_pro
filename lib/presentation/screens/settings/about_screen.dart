import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:notepad_pro/presentation/screens/privacy_policy_screen.dart';
import 'package:notepad_pro/presentation/screens/settings/app_guide_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back,
                size: 14, color: Color(0xFF6C5CE7)),
            ),
          ),
          const SizedBox(width: 8),
          const Text("About Notepad Pro",
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540))),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
        children: [
          // SECTION 1 — HERO CARD
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            child: Column(
              children: [
                // App icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shield_outlined,
                    size: 30, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // App name
                const Text("Notepad Pro",
                  style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540))),
                const SizedBox(height: 4),

                // Tagline
                const Text(
                  "Aapke notes secure, organized aur hamesha "
                  "aapke saath — chahe online ho ya offline",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11,
                    color: Color(0xFF9B8DB8), height: 1.6),
                ),
                const SizedBox(height: 12),

                // Version strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("Version 1.0.0",
                        style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C5CE7))),
                    ),
                    _dot(),
                    const Text("June 2026",
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                    _dot(),
                    const Text("Android",
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 3 — APP KI KHASIYAT (features)
          _sectionLabel("App ki khasiyat"),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            child: Column(children: [
              _featureRow(
                iconBg: const Color(0xFFEDE9F8),
                iconColor: const Color(0xFF6C5CE7),
                icon: Icons.folder_outlined,
                title: "Color-coded folders",
                desc: "Notes ko apne pasandida rang ke folders mein "
                  "organize karein. Har folder alag colour ka ho sakta hai.",
              ),
              _divider(),
              _featureRow(
                iconBg: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF0F6E56),
                icon: Icons.cloud_upload_outlined,
                title: "Google Drive backup",
                desc: "Google se sign in karein to notes automatically "
                  "Drive mein safe ho jaate hain. Offline bhi kaam karta hai.",
              ),
              _divider(),
              _featureRow(
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                icon: Icons.search_outlined,
                title: "Smart search",
                desc: "Koi bhi lafz likhein — note ke andar se bhi "
                  "results dhundhta hai, Urdu mein bhi.",
              ),
              _divider(),
              _featureRow(
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
                icon: Icons.bookmark_outline,
                title: "Book & Video reference",
                desc: "Har note ke saath book ka page number ya "
                  "video ka timestamp attach karein.",
              ),
              _divider(),
              _featureRow(
                iconBg: const Color(0xFFFCE4EC),
                iconColor: const Color(0xFFAD1457),
                icon: Icons.picture_as_pdf_outlined,
                title: "PDF export & print",
                desc: "Notes ko PDF mein save karein ya seedha "
                  "printer pe bhejein.",
              ),
              _divider(),
              _featureRow(
                iconBg: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF6A1B9A),
                icon: Icons.dark_mode_outlined,
                title: "Dark mode",
                desc: "Raat ko padhne ke liye aankhon ko "
                  "comfortable dark theme.",
                isLast: true,
              ),
            ]),
          ),
          const SizedBox(height: 9),

          // SECTION 4 — APP KI MALOMAT (info rows)
          _sectionLabel("App ki malomat"),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            child: Column(children: [
              _infoRow(
                iconBg: const Color(0xFFEDE9F8),
                iconColor: const Color(0xFF6C5CE7),
                icon: Icons.info_outline,
                label: "Version",
                value: "1.0.0 (build 100)",
              ),
              _infoRow(
                iconBg: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF0F6E56),
                icon: Icons.calendar_today_outlined,
                label: "Release date",
                value: "June 2026",
              ),
              _infoRow(
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                icon: Icons.phone_android_outlined,
                label: "Platform",
                value: "Android 8.0+",
              ),
              _infoRow(
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
                icon: Icons.language_outlined,
                label: "Zubaan",
                value: "Urdu · English",
              ),
              _infoRow(
                iconBg: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF6A1B9A),
                icon: Icons.storage_outlined,
                label: "Data storage",
                value: "Local + Google Drive",
                isLast: true,
              ),
            ]),
          ),
          const SizedBox(height: 9),

          // SECTION 5 — REVIEW & RABTA
          _sectionLabel("Review & rabta"),

          // Rate card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_outline,
                  size: 18, color: Color(0xFF6C5CE7)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("App ko rate karein",
                      style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2540))),
                    Text("Play Store pe review dein",
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(
                    'market://details?id=com.notepad.pro.notes'),
                    mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Rate karein",
                    style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 7),

          // Links card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            child: Column(children: [
              _linkRow(
                iconBg: const Color(0xFFEDE9F8),
                iconColor: const Color(0xFF6C5CE7),
                icon: Icons.mail_outline,
                label: "Feedback ya masla report karein",
                onTap: () {
                  launchUrl(Uri.parse(
                    'mailto:support@notepadpro.com'));
                },
              ),
              _divider(),
              _linkRow(
                iconBg: const Color(0xFFE1F5EE),
                iconColor: const Color(0xFF0F6E56),
                icon: Icons.shield_outlined,
                label: "Privacy Policy",
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen())),
              ),
              _divider(),
              _linkRow(
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
                icon: Icons.book_outlined,
                label: "App Guide",
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const AppGuideScreen())),
                isLast: true,
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Copyright
          const Center(
            child: Text(
              "© 2026 Notepad Pro · Tamam huqooq mahfooz hain",
              style: TextStyle(
                fontSize: 10, color: Color(0xFFC4B8E0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      width: 3, height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFD8D0F0),
        shape: BoxShape.circle),
    ),
  );

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9B8DB8),
          letterSpacing: 0.5,
        )),
    );
  }

  Widget _featureRow({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 13, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540))),
                const SizedBox(height: 2),
                Text(desc,
                  style: const TextStyle(fontSize: 10,
                    color: Color(0xFF9B8DB8), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    indent: 13, endIndent: 13,
    color: Color(0xFFF5F0FF),
    thickness: 0.5,
  );

  Widget _infoRow({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13, vertical: 10),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 9),
          Text(label,
            style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540))),
          const Spacer(),
          Text(value,
            style: const TextStyle(fontSize: 11,
              color: Color(0xFF9B8DB8))),
        ]),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 13, endIndent: 13,
          color: Color(0xFFF5F0FF), thickness: 0.5),
    ]);
  }

  Widget _linkRow({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
        ? const BorderRadius.vertical(
            bottom: Radius.circular(12))
        : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13, vertical: 10),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
              style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540))),
          ),
          const Icon(Icons.chevron_right,
            size: 16, color: Color(0xFFC4B8E0)),
        ]),
      ),
    );
  }
}
