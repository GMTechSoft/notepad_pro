import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:notepad_pro/presentation/screens/privacy_policy_screen.dart';
import 'package:notepad_pro/presentation/screens/settings/app_guide_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:notepad_pro/data/app_content/about_notepilot_data.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _versionBadge = "Version Unknown";
  String _versionInfo = "Unknown";

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      if (!mounted) return;

      if (version.isEmpty && buildNumber.isEmpty) {
        setState(() {
          _versionBadge = "Version Unknown";
          _versionInfo = "Unknown";
        });
        return;
      }

      final badgeStr =
          version.isNotEmpty ? "Version $version" : "Version Unknown";
      String infoStr;
      if (version.isNotEmpty && buildNumber.isNotEmpty) {
        infoStr = "$version (Build $buildNumber)";
      } else if (version.isNotEmpty) {
        infoStr = version;
      } else {
        infoStr = "Unknown";
      }

      setState(() {
        _versionBadge = badgeStr;
        _versionInfo = infoStr;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionBadge = "Version Unknown";
        _versionInfo = "Unknown";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoList = AboutNotePilotData.getInformation(_versionInfo);
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: context.highlightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back,
                size: 14, color: context.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(AboutNotePilotData.pageTitle,
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.primaryText)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
        children: [
          // SECTION 1 — HERO CARD
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.border, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
            child: Column(
              children: [
                // App icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shield_outlined,
                    size: 30, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // App name
                Text(AboutNotePilotData.appName,
                  style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText)),
                const SizedBox(height: 4),

                // Tagline
                Text(
                  AboutNotePilotData.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11,
                    color: context.subText, height: 1.6),
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
                        color: context.highlightBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_versionBadge,
                        style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: context.primaryColor)),
                    ),
                    _dot(context),
                    Text(AboutNotePilotData.releaseDateBadge,
                      style: TextStyle(fontSize: 10,
                        color: context.subText)),
                    _dot(context),
                    Text(AboutNotePilotData.platformBadge,
                      style: TextStyle(fontSize: 10,
                        color: context.subText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 3 — APP KI KHASIYAT (features)
          _sectionLabel(context, AboutNotePilotData.featuresSectionLabel),

          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.border, width: 0.5),
            ),
            child: Column(
              children: AboutNotePilotData.features.map((feature) {
                final isLast = feature == AboutNotePilotData.features.last;
                return Column(
                  children: [
                    _buildFeatureRowFromData(context, feature),
                    if (!isLast) _divider(context),
                  ]
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 4 — APP KI MALOMAT (info rows)
          _sectionLabel(context, AboutNotePilotData.infoSectionLabel),

          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.border, width: 0.5),
            ),
            child: Column(
              children: infoList.map((info) {
                final isLast = info == infoList.last;
                return _buildInfoRowFromData(context, info, isLast: isLast);
              }).toList(),
            ),
          ),
          const SizedBox(height: 9),

          // SECTION 5 — REVIEW & RABTA
          _sectionLabel(context, AboutNotePilotData.reviewSectionLabel),

          // Rate card
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.border, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: context.highlightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.star_outline,
                  size: 18, color: context.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AboutNotePilotData.rateAppTitle,
                      style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.primaryText)),
                    Text(AboutNotePilotData.rateAppDesc,
                      style: TextStyle(fontSize: 10,
                        color: context.subText)),
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
                    color: context.primaryColor,
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
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.border, width: 0.5),
            ),
            child: Column(
              children: AboutNotePilotData.links.map((link) {
                final isLast = link == AboutNotePilotData.links.last;
                return Column(
                  children: [
                    _buildLinkRowFromData(link, context, isLast: isLast),
                    if (!isLast) _divider(context),
                  ]
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Copyright
          Center(
            child: Text(
              AboutNotePilotData.copyrightText,
              style: TextStyle(
                fontSize: 10, color: context.border),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      width: 3, height: 3,
      decoration: BoxDecoration(
        color: context.border,
        shape: BoxShape.circle),
    ),
  );

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: context.subText,
          letterSpacing: 0.5,
        )),
    );
  }

  Widget _buildFeatureRowFromData(BuildContext context, AboutFeatureData data) {
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
                  style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.primaryText)),
                const SizedBox(height: 2),
                Text(data.desc,
                  style: TextStyle(fontSize: 10,
                    color: context.subText, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
    height: 1,
    indent: 13, endIndent: 13,
    color: context.border,
    thickness: 0.5,
  );

  Widget _buildInfoRowFromData(BuildContext context, AboutInfoData data, {bool isLast = false}) {
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
            style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.primaryText)),
          const Spacer(),
          Text(data.value,
            style: TextStyle(fontSize: 11,
              color: context.subText)),
        ]),
      ),
      if (!isLast)
        Divider(height: 1, indent: 13, endIndent: 13,
          color: context.border, thickness: 0.5),
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
              style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.primaryText)),
          ),
          Icon(Icons.chevron_right,
            size: 16, color: context.border),
        ]),
      ),
    );
  }
}
