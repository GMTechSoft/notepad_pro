import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
            // Back button
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF6C5CE7)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
        children: [
          const SizedBox(height: 4),

          // ── ITEM 1: DATE PILL ──────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF9B8DB8)),
                  const SizedBox(width: 6),
                  const Text(
                    "Effective: June 14, 2026",
                    style: TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),

          // ── ITEM 2: TABLE OF CONTENTS ──────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CONTENTS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9B8DB8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 7),
                _buildTocItem("1", "100% Offline (by default)", showBadge: false),
                _buildTocDivider(),
                _buildTocItem(
                  "2",
                  "Google Sign In & Drive Sync",
                  showBadge: true,
                  badgeText: "Important",
                  badgeBg: const Color(0xFFE1F5EE),
                  badgeColor: const Color(0xFF0F6E56),
                ),
                _buildTocDivider(),
                _buildTocItem("3", "Reference Tracking"),
                _buildTocDivider(),
                _buildTocItem("4", "Storage Permission"),
                _buildTocDivider(),
                _buildTocItem("5", "Data Security"),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── ITEM 3: SECTION 1 — Offline ────────
          _buildSection(
            iconBg: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF0F6E56),
            icon: Icons.wifi_off_outlined,
            title: "1. 100% Offline (by default)",
            body:
                "Jab tak aap Google se sign in nahi karte, aapka koi bhi data bahari servers pe nahi jata. Sab kuch sirf aapki device pe rehta hai.",
          ),
          const SizedBox(height: 9),

          // ── ITEM 4: SECTION 2 — Google (special card) ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4285F4), width: 1),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "G",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "2. Google Sign In & Drive Sync",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D2540),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Optional",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Intro
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
                    children: [
                      TextSpan(text: "Yeh feature "),
                      TextSpan(
                        text: "bilkul optional",
                        style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                      ),
                      TextSpan(text: " hai. Agar aap Google se sign in karein to:"),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 4 bullet points
                _buildBullet(
                  "Google account info",
                  " (naam, email, profile photo) app mein display hota hai",
                ),
                _buildBullet("Aapke notes aur folders", " Google Drive mein encrypted backup hote hain"),
                _buildBullet("Offline notes", " internet connect hone pe automatically sync hote hain"),
                _buildBullet(
                  "Hum aapka data",
                  " kabhi nahi padhte — Drive access sirf backup ke liye hai",
                ),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE3F2FD), thickness: 0.5),
                ),

                // User controls box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Aapka control:",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D2540),
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildControlRow(Icons.toggle_on_outlined, "Settings se kabhi bhi sync band karein"),
                      _buildControlRow(Icons.logout_outlined, "Sign out karne se Drive sync ruk jata hai"),
                      _buildControlRow(
                        Icons.delete_outline,
                        "Drive data Google account settings se delete karein",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── ITEM 5: SECTION 3 — Reference ──────
          _buildSection(
            iconBg: const Color(0xFFEDE9F8),
            iconColor: const Color(0xFF6C5CE7),
            icon: Icons.bookmark_outline,
            title: "3. Reference Tracking",
            body:
                "Book aur video references sirf aapki device ke local database mein save hote hain. Kisi third party ke saath share nahi hote.",
          ),
          const SizedBox(height: 9),

          // ── ITEM 6: SECTION 4 — Storage ────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_outlined, size: 14, color: Color(0xFFE65100)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "4. Storage Permission",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2540),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  "Yeh permissions sirf in features ke liye maangi jaati hain:",
                  style: TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
                ),
                const SizedBox(height: 4),
                _buildBullet("PDF Export", " — notes ko PDF mein local storage mein save karna"),
                _buildBullet("Printing", " — local ya network printer pe document bhejna"),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── ITEM 7: SECTION 5 — Security ───────
          _buildSection(
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            icon: Icons.shield_outlined,
            title: "5. Data Security",
            body:
                "Hum koi analytics, tracking, ya advertising use nahi karte. Google Drive mein jo data jata hai wo Google ki apni security policies ke tehat mehfooz rehta hai.",
          ),
          const SizedBox(height: 9),

          // ── ITEM 8: WARNING BANNER ──────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF795548)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Google Drive sync optional hai. Sign in na karein to data 100% local rehta hai.",
                    style: TextStyle(fontSize: 10, color: Color(0xFF795548), height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── ITEM 9: TRUST CARD ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 15, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Aapka data sirf aapka hai — hum na bechte hain, na padhte hain.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF534AB7), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildTocItem(
    String num,
    String title, {
    bool showBadge = false,
    String? badgeText,
    Color? badgeBg,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF2D2540)),
            ),
          ),
          if (showBadge && badgeText != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: badgeColor),
              ),
            ),
          const Icon(Icons.chevron_right, size: 13, color: Color(0xFFC4B8E0)),
        ],
      ),
    );
  }

  Widget _buildTocDivider() {
    return const Divider(height: 1, color: Color(0xFFF0EBF8), thickness: 0.5);
  }

  Widget _buildBullet(String boldText, String normalText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "·  ",
            style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, height: 1.6),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.6),
                children: [
                  TextSpan(
                    text: boldText,
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                  ),
                  TextSpan(text: normalText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380)),
            ),
          ),
        ],
      ),
    );
  }
}
