import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/data/app_content/privacy_policy_data.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final warningBg = context.isDark ? const Color(0xFF422E1A) : const Color(0xFFFFF3E0);
    final warningBorder = context.isDark ? const Color(0xFF634A2F) : const Color(0xFFFFE082);
    final warningText = context.isDark ? const Color(0xFFFFB74D) : const Color(0xFF795548);
    final trustText = context.isDark ? const Color(0xFFBBADFF) : const Color(0xFF534AB7);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
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
                  color: context.highlightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back, size: 14, color: context.primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              PrivacyPolicyData.pageTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.primaryText,
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
                color: context.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: context.subText),
                  const SizedBox(width: 6),
                  Text(
                    PrivacyPolicyData.effectiveDate,
                    style: TextStyle(fontSize: 10, color: context.subText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),

          // ── TABLE OF CONTENTS ──────────
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border, width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PrivacyPolicyData.tocHeader,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: context.subText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 7),
                ...PrivacyPolicyData.tocItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TocItemData item = entry.value;
                  return Column(
                    children: [
                      _buildTocItemFromData(context, item),
                      if (idx < PrivacyPolicyData.tocItems.length - 1) _buildTocDivider(context),
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
              sectionWidget = _buildStandardSection(context, section);
            } else if (section is GoogleSectionData) {
              sectionWidget = _buildGoogleSection(context, section);
            } else if (section is BulletSectionData) {
              sectionWidget = _buildBulletSection(context, section);
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
              color: warningBg,
              border: Border.all(color: warningBorder, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: warningText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PrivacyPolicyData.warningBanner.text,
                    style: TextStyle(fontSize: 10, color: warningText, height: 1.6),
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
              color: context.highlightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 15, color: context.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PrivacyPolicyData.trustCard.text,
                    style: TextStyle(fontSize: 11, color: trustText, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardSection(BuildContext context, StandardSectionData data) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            data.body,
            style: TextStyle(fontSize: 10, color: context.subText, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSection(BuildContext context, BulletSectionData data) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            data.intro,
            style: TextStyle(fontSize: 10, color: context.subText, height: 1.7),
          ),
          const SizedBox(height: 4),
          ...data.bullets.map((b) => _buildBulletFromData(context, b)),
        ],
      ),
    );
  }

  Widget _buildGoogleSection(BuildContext context, GoogleSectionData data) {
    final gBg = context.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD);
    final gColor = context.isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
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
                  color: gBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "G",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: gColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: gBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data.badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: gColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 10, color: context.subText, height: 1.7),
              children: [
                TextSpan(text: data.introPrefix),
                TextSpan(
                  text: data.introBold,
                  style: TextStyle(fontWeight: FontWeight.w500, color: context.primaryText),
                ),
                TextSpan(text: data.introSuffix),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...data.bullets.map((b) => _buildBulletFromData(context, b)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: gBg, thickness: 0.5),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.highlightBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.controlHeader,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 5),
                ...data.controls.map((c) => _buildControlRowFromData(context, c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTocItemFromData(BuildContext context, TocItemData data) {
    return _buildTocItem(
      context,
      data.numStr,
      data.title,
      showBadge: data.showBadge,
      badgeText: data.badgeText,
      badgeBg: data.badgeBg,
      badgeColor: data.badgeColor,
    );
  }

  Widget _buildTocItem(
    BuildContext context,
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
              color: context.highlightBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: context.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: context.primaryText),
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
          Icon(Icons.chevron_right, size: 13, color: context.border),
        ],
      ),
    );
  }

  Widget _buildTocDivider(BuildContext context) {
    return Divider(height: 1, color: context.border, thickness: 0.5);
  }

  Widget _buildBulletFromData(BuildContext context, BulletData data) {
    return _buildBullet(context, data.bold, data.normal);
  }

  Widget _buildBullet(BuildContext context, String boldText, String normalText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "·  ",
            style: TextStyle(color: context.primaryColor, fontSize: 12, height: 1.6),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 10, color: context.subText, height: 1.6),
                children: [
                  TextSpan(
                    text: boldText,
                    style: TextStyle(fontWeight: FontWeight.w500, color: context.primaryText),
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

  Widget _buildControlRowFromData(BuildContext context, ControlData data) {
    return _buildControlRow(context, data.icon, data.text);
  }

  Widget _buildControlRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: context.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: context.subText),
            ),
          ),
        ],
      ),
    );
  }
}
