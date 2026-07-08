import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/data/app_content/privacy_policy_data.dart';

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
              PrivacyPolicyData.pageTitle,
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

          // ── DATE PILL ──────────────────
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
                  SizedBox(width: 6),
                  Text(
                    PrivacyPolicyData.effectiveDate,
                    style: TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),

          // ── TABLE OF CONTENTS ──────────
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
                  PrivacyPolicyData.tocHeader,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9B8DB8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 7),
                ...PrivacyPolicyData.tocItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TocItemData item = entry.value;
                  return Column(
                    children: [
                      _buildTocItemFromData(item),
                      if (idx < PrivacyPolicyData.tocItems.length - 1) _buildTocDivider(),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── SECTIONS ────────
          ...PrivacyPolicyData.sections.map((section) {
            Widget sectionWidget = const SizedBox.shrink();
            if (section is StandardSectionData) {
              sectionWidget = _buildStandardSection(section);
            } else if (section is GoogleSectionData) {
              sectionWidget = _buildGoogleSection(section);
            } else if (section is BulletSectionData) {
              sectionWidget = _buildBulletSection(section);
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: sectionWidget,
            );
          }),

          // ── WARNING BANNER ──────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF795548)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PrivacyPolicyData.warningBanner.text,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF795548), height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // ── TRUST CARD ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 15, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PrivacyPolicyData.trustCard.text,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardSection(StandardSectionData data) {
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
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
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
            data.body,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSection(BulletSectionData data) {
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
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
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
            data.intro,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
          ),
          const SizedBox(height: 4),
          ...data.bullets.map((b) => _buildBulletFromData(b)),
        ],
      ),
    );
  }

  Widget _buildGoogleSection(GoogleSectionData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4285F4), width: 1),
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
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
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
                child: Text(
                  data.badgeText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: Color(0xFF6D6380), height: 1.7),
              children: [
                TextSpan(text: data.introPrefix),
                TextSpan(
                  text: data.introBold,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2540)),
                ),
                TextSpan(text: data.introSuffix),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...data.bullets.map((b) => _buildBulletFromData(b)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE3F2FD), thickness: 0.5),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.controlHeader,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540),
                  ),
                ),
                const SizedBox(height: 5),
                ...data.controls.map((c) => _buildControlRowFromData(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTocItemFromData(TocItemData data) {
    return _buildTocItem(
      data.numStr,
      data.title,
      showBadge: data.showBadge,
      badgeText: data.badgeText,
      badgeBg: data.badgeBg,
      badgeColor: data.badgeColor,
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

  Widget _buildBulletFromData(BulletData data) {
    return _buildBullet(data.bold, data.normal);
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

  Widget _buildControlRowFromData(ControlData data) {
    return _buildControlRow(data.icon, data.text);
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
