import 'package:flutter/material.dart';

class PrivacyPolicyData {
  static const String pageTitle = "Privacy Policy";
  static const String effectiveDate = "Effective: July 2026";
  
  static const String tocHeader = "CONTENTS";
  
  static final List<TocItemData> tocItems = [
    TocItemData(numStr: "1", title: "Introduction"),
    TocItemData(numStr: "2", title: "Information We Collect"),
    TocItemData(numStr: "3", title: "How Your Data Is Stored"),
    TocItemData(
      numStr: "4", 
      title: "Third-Party Services",
      showBadge: true,
      badgeText: "Important",
      badgeBg: const Color(0xFFE1F5EE),
      badgeColor: const Color(0xFF0F6E56),
    ),
    TocItemData(numStr: "5", title: "Children's Privacy"),
    TocItemData(numStr: "6", title: "Data Retention and Deletion"),
    TocItemData(numStr: "7", title: "Security"),
    TocItemData(numStr: "8", title: "Your Rights"),
    TocItemData(numStr: "9", title: "Changes to This Policy"),
    TocItemData(numStr: "10", title: "Contact Us"),
  ];

  static final List<PrivacySection> sections = [
    StandardSectionData(
      iconBg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
      icon: Icons.info_outline,
      title: "1. Introduction",
      body: "Welcome to NotePilot. This Privacy Policy explains how GMTechSoft collects, uses, and protects your information when you use the NotePilot application. By using NotePilot, you agree to the collection and use of information in accordance with this policy. NotePilot is designed to be an offline-first application, ensuring your notes remain secure and private.",
    ),
    BulletSectionData(
      iconBg: const Color(0xFFEDE9F8),
      iconColor: const Color(0xFF6C5CE7),
      icon: Icons.person_outline,
      title: "2. Information We Collect",
      intro: "We minimize data collection:",
      bullets: [
        BulletData(bold: "Information you create", normal: " — Any notes, folders, or references you create are stored entirely locally on your device."),
        BulletData(bold: "Google Account (optional)", normal: " — If you choose to sign in with Google, the application may temporarily access your basic Google account information (such as your name and email address) solely for authentication and Google Drive backup. This information is never stored on GMTechSoft servers."),
        BulletData(bold: "Information we do NOT collect", normal: " — We do not collect usage analytics, crash reports, or device identifiers. NotePilot follows your device's system appearance automatically and does not store or collect manual theme selection preferences. We do not track your behavior or share any data with advertising networks."),
      ]
    ),
    BulletSectionData(
      iconBg: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFE65100),
      icon: Icons.storage_outlined,
      title: "3. How Your Data Is Stored",
      intro: "Your data is stored securely:",
      bullets: [
        BulletData(bold: "Local storage", normal: " — By default, all your notes, images, and metadata are saved securely in your device’s local storage."),
        BulletData(bold: "Google Drive backup", normal: " — If you enable Google Drive sync, a private backup of your notes is securely uploaded to your personal Google Drive account. We do not have access to read this data outside of the app's dedicated folder."),
        BulletData(bold: "Exported files", normal: " — When you choose to export notes as PDF or text files, they are saved locally to your device's downloads or documents folder."),
      ]
    ),
    GoogleSectionData(
      title: "4. Third-Party Services",
      badgeText: "Services",
      introPrefix: "NotePilot uses the following ",
      introBold: "third-party services",
      introSuffix: " to provide optional functionality:",
      bullets: [
        BulletData(bold: "Google Sign-In", normal: " — Authentication"),
        BulletData(bold: "Google Drive API", normal: " — Backup & Restore"),
      ],
      controlHeader: "Your control:",
      controls: [
        ControlData(icon: Icons.toggle_on_outlined, text: "Disable sync anytime in settings"),
        ControlData(icon: Icons.logout_outlined, text: "Sign out to revoke Drive access"),
        ControlData(icon: Icons.delete_outline, text: "Delete backups via Google Account"),
      ]
    ),
    StandardSectionData(
      iconBg: const Color(0xFFFCE4EC),
      iconColor: const Color(0xFFAD1457),
      icon: Icons.child_care_outlined,
      title: "5. Children's Privacy",
      body: "Our application does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. Since NotePilot is an offline-first app, no data is collected or transmitted to our servers from any user, regardless of age.",
    ),
    BulletSectionData(
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      icon: Icons.delete_outline,
      title: "6. Data Retention and Deletion",
      intro: "Because NotePilot stores data locally, you retain complete control over your data retention:",
      bullets: [
        BulletData(bold: "Local Data", normal: " — Deleting the app will permanently delete all local notes."),
        BulletData(bold: "Cloud Backups", normal: " — You can delete your Google Drive backups at any time directly through your Google Account settings. Disconnecting your Google Account from NotePilot will also revoke the app's access to your Drive."),
      ]
    ),
    BulletSectionData(
      iconBg: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF2E7D32),
      icon: Icons.security_outlined,
      title: "7. Security",
      intro: "The security of your data is important to us:",
      bullets: [
        BulletData(bold: "No server storage", normal: " — We never store your notes on GMTechSoft servers."),
        BulletData(bold: "Encrypted transit", normal: " — Data transmitted to Google Drive for backup purposes is encrypted in transit using industry-standard HTTPS."),
      ]
    ),
    StandardSectionData(
      iconBg: const Color(0xFFFFF8E1),
      iconColor: const Color(0xFFF57F17),
      icon: Icons.gavel_outlined,
      title: "8. Your Rights",
      body: "You have the right to access, modify, and delete your notes at any time directly within the NotePilot application. Because we do not store your data on our servers, we cannot access, retrieve, or delete your notes on your behalf. You manage your data completely independently.",
    ),
    StandardSectionData(
      iconBg: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF6A1B9A),
      icon: Icons.update_outlined,
      title: "9. Changes to This Policy",
      body: "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page within the application. You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.",
    ),
    StandardSectionData(
      iconBg: const Color(0xFFE0F7FA),
      iconColor: const Color(0xFF00838F),
      icon: Icons.mail_outline,
      title: "10. Contact Us",
      body: "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.\n\nDeveloper: GMTechSoft\nEmail: gmtechsoft.dev@gmail.com\n\nThis Privacy Policy applies to NotePilot version 1.0.0 and later, available on Android.",
    ),
  ];

  static final WarningBannerData warningBanner = WarningBannerData(
    text: "Google Drive sync is optional. If you do not sign in, your data remains 100% local.",
  );

  static final TrustCardData trustCard = TrustCardData(
    text: "Your data is yours — we do not sell or read your notes.",
  );
}

abstract class PrivacySection {}

class TocItemData {
  final String numStr;
  final String title;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeColor;

  TocItemData({
    required this.numStr,
    required this.title,
    this.showBadge = false,
    this.badgeText,
    this.badgeBg,
    this.badgeColor,
  });
}

class StandardSectionData extends PrivacySection {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String body;

  StandardSectionData({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.body,
  });
}

class GoogleSectionData extends PrivacySection {
  final String title;
  final String badgeText;
  final String introPrefix;
  final String introBold;
  final String introSuffix;
  final List<BulletData> bullets;
  final String controlHeader;
  final List<ControlData> controls;

  GoogleSectionData({
    required this.title,
    required this.badgeText,
    required this.introPrefix,
    required this.introBold,
    required this.introSuffix,
    required this.bullets,
    required this.controlHeader,
    required this.controls,
  });
}

class BulletSectionData extends PrivacySection {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String intro;
  final List<BulletData> bullets;
  
  BulletSectionData({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.intro,
    required this.bullets,
  });
}

class BulletData {
  final String bold;
  final String normal;

  BulletData({required this.bold, required this.normal});
}

class ControlData {
  final IconData icon;
  final String text;

  ControlData({required this.icon, required this.text});
}

class WarningBannerData {
  final String text;
  WarningBannerData({required this.text});
}

class TrustCardData {
  final String text;
  TrustCardData({required this.text});
}
