import 'package:flutter/material.dart';

class AboutNotePilotData {
  // Hero Section
  static const String pageTitle = "About NotePilot";
  static const String appName = "NotePilot";
  static const String appTagline =
      "A powerful offline-first notes and knowledge management application designed to help you organize ideas, research, documents, and references securely.";
  static const String versionBadge = "Version Unknown";
  static const String releaseDateBadge = "July 2026";
  static const String platformBadge = "Android";

  static const String shortDescription =
      "Create folders, write rich notes, attach book and video references, search instantly, export documents, and securely back up your data to Google Drive.";

  // Section labels
  static const String featuresSectionLabel = "FEATURES";
  static const String infoSectionLabel = "APPLICATION INFORMATION";
  static const String reviewSectionLabel = "REVIEW SECTION";

  // Features List
  static final List<AboutFeatureData> features = [
    AboutFeatureData(
      iconBg: const Color(0xFFEDE9F8),
      iconColor: const Color(0xFF6C5CE7),
      icon: Icons.folder_outlined,
      title: "Smart Folder Management",
      desc:
          "Create unlimited folders with custom colors to organize your notes exactly the way you want.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
      icon: Icons.edit_note_outlined,
      title: "Rich Notes",
      desc:
          "Create detailed notes with titles and descriptions. Notes are automatically saved while you work.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      icon: Icons.menu_book_outlined,
      title: "Book References",
      desc:
          "Attach book references including:\n• Book Name\n• Author\n• Volume\n• Page Number\n• Line Number",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFE65100),
      icon: Icons.play_circle_outline,
      title: "Video References",
      desc:
          "Attach video references including:\n• Video Title\n• Hours\n• Minutes\n• Seconds\n\nPerfect for lectures, courses and research material.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFFCE4EC),
      iconColor: const Color(0xFFAD1457),
      icon: Icons.search_outlined,
      title: "Powerful Search",
      desc:
          "Instantly search notes using one or multiple words.\nHighlighted matching words\nResult count for every note\nFast local search\nSupports both English and Urdu.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF6A1B9A),
      icon: Icons.drive_file_move_outlined,
      title: "Move & Organize",
      desc:
          "Move folders or notes between directories.\nSupports:\n• Single move\n• Multi-selection move\n• Root directory move",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFEDE9F8),
      iconColor: const Color(0xFF6C5CE7),
      icon: Icons.print_outlined,
      title: "Export & Print",
      desc:
          "Export notes as:\n• PDF\n• Microsoft Word\n• Plain Text\n\nPrint notes directly from the application.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
      icon: Icons.cloud_upload_outlined,
      title: "Google Drive Backup",
      desc:
          "Securely back up and restore your notes using your own Google Drive account.\nAutomatic synchronization after sign in.\nOffline changes sync automatically when internet becomes available.\nManual Backup Now option when data is waiting to sync.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      icon: Icons.wifi_off_outlined,
      title: "Offline First",
      desc:
          "Everything works without an internet connection.\nInternet is only required for Google Drive backup and restore.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFE65100),
      icon: Icons.dark_mode_outlined,
      title: "System Theme",
      desc:
          "NotePilot automatically follows your device's system appearance.\nTo switch between Light and Dark modes, change your device's system theme.",
    ),
    AboutFeatureData(
      iconBg: const Color(0xFFFCE4EC),
      iconColor: const Color(0xFFAD1457),
      icon: Icons.language_outlined,
      title: "Multilingual Support",
      desc:
          "English interface (Left-to-Right)\nUrdu notes automatically displayed Right-to-Left.",
    ),
  ];

  // Info List
  static List<AboutInfoData> getInformation(String versionValue) => [
        AboutInfoData(
          iconBg: const Color(0xFFEDE9F8),
          iconColor: const Color(0xFF6C5CE7),
          icon: Icons.info_outline,
          label: "Version",
          value: versionValue,
        ),
        AboutInfoData(
          iconBg: const Color(0xFFE1F5EE),
          iconColor: const Color(0xFF0F6E56),
          icon: Icons.calendar_today_outlined,
          label: "Release Date",
          value: "July 2026",
        ),
        AboutInfoData(
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          icon: Icons.phone_android_outlined,
          label: "Platform",
          value: "Android",
        ),
        AboutInfoData(
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFE65100),
          icon: Icons.language_outlined,
          label: "Languages",
          value: "English & Urdu",
        ),
        AboutInfoData(
          iconBg: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF6A1B9A),
          icon: Icons.storage_outlined,
          label: "Storage",
          value: "Local Database (Hive)\nOptional Google Drive Backup",
        ),
        AboutInfoData(
          iconBg: const Color(0xFFEDE9F8),
          iconColor: const Color(0xFF6C5CE7),
          icon: Icons.person_outline,
          label: "Developer",
          value: "GMTechSoft",
        ),
      ];

  static List<AboutInfoData> get information => getInformation("Unknown");

  // Review & Rabta
  static const String rateAppTitle = "Enjoying NotePilot?";
  static const String rateAppDesc =
      "Rate us on Google Play and help other users discover NotePilot.";
  static const String rateAppButton = "Rate us";
  static const String rateAppUrl =
      "market://details?id=com.gmtechsoft.notepilot";

  static final List<AboutLinkData> links = [
    AboutLinkData(
      iconBg: const Color(0xFFEDE9F8),
      iconColor: const Color(0xFF6C5CE7),
      icon: Icons.mail_outline,
      label: "Need Help? Contact us anytime.",
      url: "mailto:gmtechsoft.dev@gmail.com",
    ),
    AboutLinkData(
      iconBg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
      icon: Icons.shield_outlined,
      label: "Privacy Policy",
      isPrivacyPolicy: true,
    ),
    AboutLinkData(
      iconBg: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      icon: Icons.book_outlined,
      label: "App Guide",
      isAppGuide: true,
    ),
  ];

  // Copyright
  static const String copyrightText = "© 2026 GMTechSoft\nAll Rights Reserved.";
}

class AboutFeatureData {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String desc;

  AboutFeatureData({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class AboutInfoData {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;

  AboutInfoData({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
  });
}

class AboutLinkData {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String? url;
  final bool isPrivacyPolicy;
  final bool isAppGuide;

  AboutLinkData({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    this.url,
    this.isPrivacyPolicy = false,
    this.isAppGuide = false,
  });
}
