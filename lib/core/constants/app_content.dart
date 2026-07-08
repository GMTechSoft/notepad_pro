// import 'package:flutter/material.dart';

// // ════════════════════════════════════
// // APP CONTENT — SINGLE SOURCE OF TRUTH
// // Sirf yahan update karein — sab
// // screens automatically update ho
// // jaati hain.
// // ════════════════════════════════════

// class AppContent {

//   // ── APP INFO ─────────────────────
//   static const String appName =
//     'NotePilot';

//   static const String appTagline =
//     'Aapke notes secure, organized'
//     ' aur hamesha aapke saath —'
//     ' chahe online ho ya offline';

//   static const String appVersion =
//     '1.0.1';

//   static const String appBuild =
//     '100';

//   static const String releaseDate =
//     'June 2026';

//   static const String platform =
//     'Android 8.0+';

//   static const String languages =
//     'Urdu · English';

//   static const String dataStorage =
//     'Local + Google Drive';

//   static const String copyright =
//     '© 2026 NotePilot · Tamam'
//     ' huqooq mahfooz hain';

//   // ── CONTACT & LINKS ──────────────
//   static const String feedbackEmail =
//     'support@notepilot.app';
//     // apna email yahan likhein

//   static const String privacyPolicyUrl =
//     'https://notepilot.app/privacy';
//     // apni policy URL yahan

//   static const String playStoreUrl =
//     'https://play.google.com/store/'
//     'apps/details?id=com.notepilot';
//     // apna Play Store link yahan

//   // ── APP FEATURES LIST ─────────────
//   // About screen pe "App ki khasiyat"
//   // mein yahi list show hogi.
//   // Naya feature add karna ho to
//   // bas yahan add karo.

//   static const List<AppFeature>
//     features = [

//     AppFeature(
//       iconName: 'folder',
//       iconColorHex: '6C5CE7',
//       title: 'Color-coded folders',
//       description:
//         'Notes ko apne pasandida rang'
//         ' ke folders mein organize'
//         ' karein. Har folder alag'
//         ' colour ka ho sakta hai.',
//     ),

//     AppFeature(
//       iconName: 'cloud-upload',
//       iconColorHex: '0F6E56',
//       title: 'Google Drive backup',
//       description:
//         'Google se sign in karein to'
//         ' notes automatically Drive'
//         ' mein safe ho jaate hain.'
//         ' Offline bhi kaam karta hai.',
//     ),

//     AppFeature(
//       iconName: 'search',
//       iconColorHex: '0C447C',
//       title: 'Smart search',
//       description:
//         'Koi bhi lafz likhein — note'
//         ' ke andar se bhi results'
//         ' dhundha hai, Urdu mein bhi.',
//     ),

//     AppFeature(
//       iconName: 'book',
//       iconColorHex: 'C0392B',
//       title: 'Book & Video reference',
//       description:
//         'Har note ke saath book ka'
//         ' page number ya video ka'
//         ' timestamp attach karein.',
//     ),

//     AppFeature(
//       iconName: 'file-type-pdf',
//       iconColorHex: 'A32D2D',
//       title: 'PDF export & print',
//       description:
//         'Notes ko PDF mein save'
//         ' karein ya seedha printer'
//         ' pe bhejein.',
//     ),

//     AppFeature(
//       iconName: 'moon',
//       iconColorHex: '2D2540',
//       title: 'Dark mode',
//       description:
//         'Raat ko padhne ke liye'
//         ' aankhon ko comfortable'
//         ' dark theme.',
//     ),
//   ];

//   // ── PRIVACY POLICY ────────────────
//   // Har section ek Map hai:
//   // title + body
//   // Naya section add karna ho to
//   // bas list mein add karo.

//   static const List<PolicySection>
//     privacyPolicy = [

//     PolicySection(
//       title: '1. Collected data',
//       body:
//         'NotePilot sirf wahi data'
//         ' collect karta hai jo app'
//         ' ko chalane ke liye zaruri'
//         ' hai. Aapke notes sirf aapke'
//         ' device aur Google Drive'
//         ' account mein store hote'
//         ' hain — hamare servers pe'
//         ' nahi.',
//     ),

//     PolicySection(
//       title: '2. Google Drive',
//       body:
//         'Agar aap Google Drive backup'
//         ' enable karte hain to aapki'
//         ' files sirf aapke khud ke'
//         ' Drive account mein jaati'
//         ' hain. Hum in files ko dekh'
//         ' ya access nahi kar sakte.',
//     ),

//     PolicySection(
//       title: '3. No ads',
//       body:
//         'NotePilot mein koi'
//         ' advertisement nahi hai.'
//         ' Aapka data kisi bhi third'
//         ' party ko sell nahi kiya'
//         ' jaata.',
//     ),

//     PolicySection(
//       title: '4. Data deletion',
//       body:
//         'App uninstall karne se'
//         ' aapka local data delete'
//         ' ho jata hai. Drive backup'
//         ' delete karne ke liye aapko'
//         ' Google Drive mein jaana'
//         ' hoga.',
//     ),

//     PolicySection(
//       title: '5. Contact',
//       body:
//         'Privacy ke baare mein koi'
//         ' sawal ho to humse rabta'
//         ' karein: $feedbackEmail',
//     ),

//     // ← Naya section add karo yahan
//   ];

//   // ── APP GUIDE ─────────────────────
//   // Har step ek GuideStep.
//   // Order change karna ho ya step
//   // add/remove karna ho to bas
//   // yahan update karo.

//   static const List<GuideStep>
//     appGuide = [

//     GuideStep(
//       stepNumber: '01',
//       title: 'Folder banayein',
//       description:
//         'Home screen pe "Create new"'
//         ' tap karein aur "Folder"'
//         ' chunein. Folder ka naam'
//         ' aur rang set karein.',
//       tip:
//         'Rang se folders ek nazar'
//         ' mein pehchaan aa jaate hain.',
//     ),

//     GuideStep(
//       stepNumber: '02',
//       title: 'Note likhein',
//       description:
//         'Folder ke andar "Create new"'
//         ' tap karein. Title aur'
//         ' description likhein.'
//         ' Urdu text automatic RTL'
//         ' ho jaata hai.',
//       tip: null,
//     ),

//     GuideStep(
//       stepNumber: '03',
//       title: 'Reference add karein',
//       description:
//         '"Reference add karein" toggle'
//         ' on karein. Video ka'
//         ' timestamp ya book ka page'
//         ' number save karein.',
//       tip:
//         'Reference baad mein'
//         ' search mein bhi dikh'
//         ' sakta hai.',
//     ),

//     GuideStep(
//       stepNumber: '04',
//       title: 'Search karein',
//       description:
//         'Upar search icon tap karein.'
//         ' Ek ya zyada alfaz likhein.'
//         ' Results mein har word'
//         ' alag color se highlight'
//         ' hota hai.',
//       tip: null,
//     ),

//     GuideStep(
//       stepNumber: '05',
//       title: 'Google Drive backup',
//       description:
//         'Settings mein Google account'
//         ' se sign in karein. Aapke'
//         ' sare notes automatically'
//         ' Drive mein save hone'
//         ' lagte hain.',
//       tip:
//         'Naya phone lene pe Drive'
//         ' se restore kar sakte hain.',
//     ),

//     GuideStep(
//       stepNumber: '06',
//       title: 'PDF export',
//       description:
//         'Note detail screen pe'
//         ' "Export" tap karein aur'
//         ' format chunein — PDF,'
//         ' Word, ya plain text.',
//       tip: null,
//     ),

//     // ← Naya step add karo yahan
//   ];
// }

// // ════════════════════════════════════
// // DATA MODELS
// // ════════════════════════════════════

// class AppFeature {
//   final String iconName;
//   final String iconColorHex;
//   final String title;
//   final String description;

//   const AppFeature({
//     required this.iconName,
//     required this.iconColorHex,
//     required this.title,
//     required this.description,
//   });

//   Color get iconColor =>
//     Color(int.parse(
//       'FF$iconColorHex', radix: 16));
// }

// class PolicySection {
//   final String title;
//   final String body;

//   const PolicySection({
//     required this.title,
//     required this.body,
//   });
// }

// class GuideStep {
//   final String stepNumber;
//   final String title;
//   final String description;
//   final String? tip;

//   const GuideStep({
//     required this.stepNumber,
//     required this.title,
//     required this.description,
//     this.tip,
//   });
// }
