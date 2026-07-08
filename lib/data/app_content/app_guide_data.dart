import 'package:flutter/material.dart';

class AppGuideData {
  static const String pageTitle = "App Guide";

  // 1. Hero Banner
  static const HeroBannerData heroBanner = HeroBannerData(
    title: "Welcome to NotePilot",
    subtitle: "Your secure offline notes and research companion.\nOrganize ideas, manage references, search instantly, and keep everything safely backed up in Google Drive.",
    chips: [
      "Offline First",
      "Google Drive Backup",
      "Smart Search",
      "Auto Save",
      "PDF Export",
      "Dark Mode",
    ],
  );

  // 2. Interactive Quick Start
  static const String quickStartTitle = "Quick Start";
  static final List<QuickStartStep> quickStartSteps = [
    QuickStartStep(
      icon: Icons.folder_outlined,
      title: "Create Folder",
      description: "Organize your notes",
    ),
    QuickStartStep(
      icon: Icons.note_add_outlined,
      title: "Create Note",
      description: "Write your ideas",
    ),
    QuickStartStep(
      icon: Icons.search_outlined,
      title: "Search Notes",
      description: "Find instantly",
    ),
    QuickStartStep(
      icon: Icons.cloud_done_outlined,
      title: "Enable Google Drive Backup",
      description: "Keep data safe",
    ),
  ];

  // 3. Complete Illustrated Guide
  static const String guideTitle = "Complete Guide";
  static final List<FeatureGuideItem> guideItems = [
    FeatureGuideItem(
      icon: Icons.folder_open,
      title: "Create Folder",
      explanation: "Create New\nFolder\nFolder Name\nFolder Color\nCreate\nCancel",
      tip: "Custom colors help organize your workspace.",
    ),
    FeatureGuideItem(
      icon: Icons.edit_document,
      title: "Create Note",
      explanation: "Create New\nFile\nTitle\nDescription\nAuto Save\n\nEvery change is automatically saved.",
    ),
    FeatureGuideItem(
      icon: Icons.library_books,
      title: "References",
      explanation: "Book Reference:\n• Book Name\n• Author\n• Volume\n• Page\n• Line\n\nVideo Reference:\n• Video Title\n• Hour\n• Minute\n• Second\n\nNote: References are optional.",
    ),
    FeatureGuideItem(
      icon: Icons.manage_search,
      title: "Smart Search",
      explanation: "• Single keyword search\n• Multiple keyword search\n• Highlighted matching words\n• Result count for each note\n• English support\n• Urdu support",
    ),
    FeatureGuideItem(
      icon: Icons.drive_file_move_outline,
      title: "Move & Organize",
      explanation: "• Move files\n• Move folders\n• Move multiple files\n• Move multiple folders\n• Move items back to Root Directory",
    ),
    FeatureGuideItem(
      icon: Icons.print_outlined,
      title: "Export & Print",
      explanation: "• Export PDF\n• Export Word\n• Export Text\n• Print Notes",
    ),
    FeatureGuideItem(
      icon: Icons.cloud_upload_outlined,
      title: "Google Drive Backup",
      explanation: "• Google Sign In\n• Automatic Backup\n• Restore\n• Offline editing\n• Automatic Sync\n• Backup Now\n\nYour backup stays inside YOUR Google Drive account. GMTechSoft never stores your notes.",
    ),
    FeatureGuideItem(
      icon: Icons.color_lens_outlined,
      title: "Customize Experience",
      explanation: "• Dark Mode\n• Light Mode\n• English (LTR)\n• Urdu (RTL)",
    ),
  ];

  // 4. Feature Showcase
  static const String showcaseTitle = "Everything NotePilot Can Do";
  static final List<FeatureShowcaseItem> showcaseItems = [
    FeatureShowcaseItem(icon: Icons.folder, title: "Folders"),
    FeatureShowcaseItem(icon: Icons.note, title: "Notes"),
    FeatureShowcaseItem(icon: Icons.save, title: "Auto Save"),
    FeatureShowcaseItem(icon: Icons.search, title: "Smart Search"),
    FeatureShowcaseItem(icon: Icons.menu_book, title: "Book References"),
    FeatureShowcaseItem(icon: Icons.video_library, title: "Video References"),
    FeatureShowcaseItem(icon: Icons.backup, title: "Google Drive Backup"),
    FeatureShowcaseItem(icon: Icons.restore, title: "Restore"),
    FeatureShowcaseItem(icon: Icons.picture_as_pdf, title: "Export PDF"),
    FeatureShowcaseItem(icon: Icons.description, title: "Export Word"),
    FeatureShowcaseItem(icon: Icons.text_snippet, title: "Export Text"),
    FeatureShowcaseItem(icon: Icons.print, title: "Printing"),
    FeatureShowcaseItem(icon: Icons.dark_mode, title: "Dark Mode"),
    FeatureShowcaseItem(icon: Icons.color_lens, title: "Folder Colors"),
    FeatureShowcaseItem(icon: Icons.drive_file_move, title: "Move Files"),
    FeatureShowcaseItem(icon: Icons.snippet_folder, title: "Move Folders"),
    FeatureShowcaseItem(icon: Icons.checklist, title: "Multi Selection"),
    FeatureShowcaseItem(icon: Icons.wifi_off, title: "Offline First"),
    FeatureShowcaseItem(icon: Icons.translate, title: "English & Urdu"),
  ];

  // 5. Tips & Best Practices
  static const String tipsTitle = "Tips & Best Practices";
  static final List<String> tips = [
    "Organize notes using folders.",
    "Use colors for categories.",
    "Enable Google Drive Backup before changing devices.",
    "Export important notes regularly.",
    "Use Smart Search instead of scrolling.",
    "Keep research references attached to notes.",
  ];

  // 6. Troubleshooting
  static const String troubleshootingTitle = "Troubleshooting";
  static final List<ExpandableItem> troubleshootingItems = [
    ExpandableItem(
      title: "Google Sign In isn't working",
      content: "Ensure you have a stable internet connection. Check if your Google account is active on the device. Try restarting the app.",
    ),
    ExpandableItem(
      title: "Backup failed",
      content: "Check your internet connection. Ensure you have enough storage space in your Google Drive. Try manually backing up from settings.",
    ),
    ExpandableItem(
      title: "Restore failed",
      content: "Ensure you are signed into the correct Google account that has the backup. Check your internet connection.",
    ),
    ExpandableItem(
      title: "Search returns no results",
      content: "Double-check the spelling of your keywords. Ensure the note containing the text hasn't been deleted.",
    ),
    ExpandableItem(
      title: "Export failed",
      content: "Check if NotePilot has storage permissions. Ensure your device has enough free storage space.",
    ),
    ExpandableItem(
      title: "Printing doesn't work",
      content: "Ensure your device is connected to a printer. Check if the printer has paper and ink. Try exporting to PDF first, then printing.",
    ),
  ];

  // 7. Frequently Asked Questions
  static const String faqTitle = "Frequently Asked Questions";
  static final List<ExpandableItem> faqItems = [
    ExpandableItem(
      title: "How do I create a folder?",
      content: "Tap 'Create New' on the home screen, then select 'Folder'.",
    ),
    ExpandableItem(
      title: "How do I move files?",
      content: "Long-press a file, select it (and others if needed), tap the move icon, and choose the destination folder.",
    ),
    ExpandableItem(
      title: "How do I restore backup?",
      content: "Go to Settings > Google Drive Backup, sign in, and tap 'Restore'.",
    ),
    ExpandableItem(
      title: "How do I print?",
      content: "Open a note, tap the options menu, and select 'Print'.",
    ),
    ExpandableItem(
      title: "How do I export PDF?",
      content: "Open a note, tap the options menu, and select 'Export PDF'.",
    ),
    ExpandableItem(
      title: "How do I change folder color?",
      content: "Edit the folder and select a new color from the color palette.",
    ),
    ExpandableItem(
      title: "How do I enable Dark Mode?",
      content: "Go to Settings > Theme and select 'Dark Mode'.",
    ),
    ExpandableItem(
      title: "How does Auto Save work?",
      content: "NotePilot automatically saves your work as you type. You don't need to press save manually.",
    ),
    ExpandableItem(
      title: "How do References work?",
      content: "References allow you to attach book or video citations to your notes for research purposes.",
    ),
  ];

  // 8. What's New
  static const String whatsNewTitle = "What's New";
  static const WhatsNewData whatsNew = WhatsNewData(
    version: "Version 1.0.0",
    releaseName: "Initial Release",
    features: [
      "Offline Notes",
      "Google Drive Backup",
      "Smart Search",
      "Export PDF",
      "Export Word",
      "Printing",
      "Dark Mode",
    ],
  );

  // 9. Need Help
  static const String needHelpTitle = "Need more help?";
  static const NeedHelpData needHelp = NeedHelpData(
    contactTitle: "Contact GMTechSoft",
    emailLabel: "Email",
    emailValue: "gmtechsoft.dev@gmail.com",
    footerText: "We usually respond within 48 hours.",
  );
}

class HeroBannerData {
  final String title;
  final String subtitle;
  final List<String> chips;
  const HeroBannerData({required this.title, required this.subtitle, required this.chips});
}

class QuickStartStep {
  final IconData icon;
  final String title;
  final String description;
  const QuickStartStep({required this.icon, required this.title, required this.description});
}

class FeatureGuideItem {
  final IconData icon;
  final String title;
  final String explanation;
  final String? tip;
  const FeatureGuideItem({required this.icon, required this.title, required this.explanation, this.tip});
}

class FeatureShowcaseItem {
  final IconData icon;
  final String title;
  const FeatureShowcaseItem({required this.icon, required this.title});
}

class ExpandableItem {
  final String title;
  final String content;
  const ExpandableItem({required this.title, required this.content});
}

class WhatsNewData {
  final String version;
  final String releaseName;
  final List<String> features;
  const WhatsNewData({required this.version, required this.releaseName, required this.features});
}

class NeedHelpData {
  final String contactTitle;
  final String emailLabel;
  final String emailValue;
  final String footerText;
  const NeedHelpData({required this.contactTitle, required this.emailLabel, required this.emailValue, required this.footerText});
}
