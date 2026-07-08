import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:notepad_pro/presentation/screens/privacy_policy_screen.dart';
import 'package:notepad_pro/presentation/screens/settings/app_guide_screen.dart';
import 'package:notepad_pro/data/app_content/about_notepilot_data.dart';

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
          const Text(AboutNotePilotData.pageTitle,
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
                const Text(AboutNotePilotData.appName,
                  style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540))),
                const SizedBox(height: 4),

                // Tagline
                const Text(
                  AboutNotePilotData.appTagline,
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
                      child: const Text(AboutNotePilotData.versionBadge,
                        style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C5CE7))),
                    ),
                    _dot(),
                    const Text(AboutNotePilotData.releaseDateBadge,
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                    _dot(),
                    const Text(AboutNotePilotData.platformBadge,
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 3 — APP KI KHASIYAT (features)
          _sectionLabel(AboutNotePilotData.featuresSectionLabel),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            child: Column(
              children: AboutNotePilotData.features.map((feature) {
                final isLast = feature == AboutNotePilotData.features.last;
                return Column(
                  children: [
                    _buildFeatureRowFromData(feature),
                    if (!isLast) _divider(),
                  ]
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 4 — APP KI MALOMAT (info rows)
          _sectionLabel(AboutNotePilotData.infoSectionLabel),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            child: Column(
              children: AboutNotePilotData.information.map((info) {
                final isLast = info == AboutNotePilotData.information.last;
                return _buildInfoRowFromData(info, isLast: isLast);
              }).toList(),
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 5 — REVIEW & RABTA
          _sectionLabel(AboutNotePilotData.reviewSectionLabel),

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
                    Text(AboutNotePilotData.rateAppTitle,
                      style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2540))),
                    Text(AboutNotePilotData.rateAppDesc,
                      style: TextStyle(fontSize: 10,
                        color: Color(0xFF9B8DB8))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(AboutNotePilotData.rateAppUrl),
                    mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(AboutNotePilotData.rateAppButton,
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
            child: Column(
              children: AboutNotePilotData.links.map((link) {
                final isLast = link == AboutNotePilotData.links.last;
                return Column(
                  children: [
                    _buildLinkRowFromData(link, context, isLast: isLast),
                    if (!isLast) _divider(),
                  ]
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Copyright
          const Center(
            child: Text(
              AboutNotePilotData.copyrightText,
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

  Widget _buildFeatureRowFromData(AboutFeatureData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 13, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, size: 16, color: data.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                  style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2540))),
                const SizedBox(height: 2),
                Text(data.desc,
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

  Widget _buildInfoRowFromData(AboutInfoData data, {bool isLast = false}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13, vertical: 10),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 14, color: data.iconColor),
          ),
          const SizedBox(width: 9),
          Text(data.label,
            style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540))),
          const Spacer(),
          Text(data.value,
            style: const TextStyle(fontSize: 11,
              color: Color(0xFF9B8DB8))),
        ]),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 13, endIndent: 13,
          color: Color(0xFFF5F0FF), thickness: 0.5),
    ]);
  }

  Widget _buildLinkRowFromData(AboutLinkData data, BuildContext context, {bool isLast = false}) {
    return InkWell(
      onTap: () {
        if (data.isPrivacyPolicy) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        } else if (data.isAppGuide) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AppGuideScreen()));
        } else if (data.url != null) {
          launchUrl(Uri.parse(data.url!));
        }
      },
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
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 14, color: data.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(data.label,
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
