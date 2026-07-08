import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _StepData {
  final int number;
  final Color numColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String desc;
  final IconData tagIcon;
  final String tagText;
  final Color tagBg;
  final Color tagTextColor;
  final bool isLast;

  const _StepData({
    required this.number,
    required this.numColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.desc,
    required this.tagIcon,
    required this.tagText,
    required this.tagBg,
    required this.tagTextColor,
    required this.isLast,
  });
}

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_StepData> steps = [
      const _StepData(
        number: 1,
        numColor: Color(0xFF6C5CE7),
        iconBg: Color(0xFFEDE9F8),
        iconColor: Color(0xFF6C5CE7),
        icon: Icons.create_new_folder_outlined,
        title: "Folder banayein",
        desc: "Neeche \"+ Create new\" tap karein, "
            "phir \"Folder\" chunein. Apna pasandida "
            "color bhi select kar sakte hain.",
        tagIcon: Icons.touch_app_outlined,
        tagText: "+ Create new → Folder",
        tagBg: Color(0xFFF5F0FF),
        tagTextColor: Color(0xFF6C5CE7),
        isLast: false,
      ),
      const _StepData(
        number: 2,
        numColor: Color(0xFF0F6E56),
        iconBg: Color(0xFFE1F5EE),
        iconColor: Color(0xFF0F6E56),
        icon: Icons.note_add_outlined,
        title: "Note likhein",
        desc: "Folder kholein aur note add karein. "
            "Book page number ya video timestamp "
            "bhi attach kar sakte hain.",
        tagIcon: Icons.bookmark_outline,
        tagText: "Reference add karna optional hai",
        tagBg: Color(0xFFF0FBF7),
        tagTextColor: Color(0xFF0F6E56),
        isLast: false,
      ),
      const _StepData(
        number: 3,
        numColor: Color(0xFF1565C0),
        iconBg: Color(0xFFE3F2FD),
        iconColor: Color(0xFF1565C0),
        icon: Icons.search_outlined,
        title: "Search karein",
        desc: "Upar search icon tap karein. "
            "Note ke andar se bhi results milte hain "
            "— Urdu aur English dono mein.",
        tagIcon: Icons.search_outlined,
        tagText: "Title aur content dono mein search",
        tagBg: Color(0xFFEBF4FE),
        tagTextColor: Color(0xFF1565C0),
        isLast: false,
      ),
      const _StepData(
        number: 4,
        numColor: Color(0xFFE65100),
        iconBg: Color(0xFFFFF3E0),
        iconColor: Color(0xFFE65100),
        icon: Icons.cloud_upload_outlined,
        title: "Backup karein",
        desc: "Settings mein jaakar Google se sign in "
            "karein. Data automatically Drive mein "
            "save hota rehega.",
        tagIcon: Icons.settings_outlined,
        tagText: "Settings → Google account",
        tagBg: Color(0xFFFFF8F0),
        tagTextColor: Color(0xFFE65100),
        isLast: true,
      ),
    ];

    final List<Map<String, dynamic>> faqs = [
      {
        'iconBg': const Color(0xFFEDE9F8),
        'iconColor': const Color(0xFF6C5CE7),
        'icon': Icons.folder_outlined,
        'text': "Folder ka color kaise badlein?",
        'answer': "Folder pe long press karein, phir "
            "\"Edit folder\" tap karein aur naya color "
            "chunein.",
      },
      {
        'iconBg': const Color(0xFFE1F5EE),
        'iconColor': const Color(0xFF0F6E56),
        'icon': Icons.cloud_outlined,
        'text': "Data Drive mein kaise jaata hai?",
        'answer': "Settings mein Google account se sign "
            "in karein. Auto sync on hone ke baad har "
            "note Drive mein save hoga.",
      },
      {
        'iconBg': const Color(0xFFFFF3E0),
        'iconColor': const Color(0xFFE65100),
        'icon': Icons.picture_as_pdf_outlined,
        'text': "PDF export kaise karein?",
        'answer': "Note kholein, upar 3-dot menu tap "
            "karein aur \"Save as PDF\" select karein.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          InkWell(
            onTap: () => context.pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 14, color: Color(0xFF6C5CE7)),
            ),
          ),
          const SizedBox(width: 8),
          const Text("App Guide",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2540))),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
        children: [
          _heroCard(),
          const SizedBox(height: 9),
          _sectionLabel("Shuru karein"),
          const SizedBox(height: 6),
          _stepsList(steps),
          const SizedBox(height: 9),
          _tipCard(),
          const SizedBox(height: 9),
          _sectionLabel("Madad chahiye?"),
          const SizedBox(height: 6),
          _faqCard(context, faqs),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9B8DB8),
          letterSpacing: 0.5,
        ));
  }

  Widget _heroCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.shield_outlined,
                size: 26, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text("Notepad Pro kaise use karein?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2540))),
          const SizedBox(height: 4),
          const Text(
              "4 aasaan steps mein apna notes vault "
              "master karein",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF9B8DB8), height: 1.6)),
        ],
      ),
    );
  }

  Widget _stepsList(List<_StepData> steps) {
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: number + connector line
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: s.numColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          s.number.toString(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    if (!s.isLast)
                      Container(
                        width: 1.5,
                        height: 20,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: s.iconBg,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),

                // Icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: s.iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(s.icon, size: 15, color: s.iconColor),
                ),
                const SizedBox(width: 10),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D2540))),
                      const SizedBox(height: 3),
                      Text(s.desc,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9B8DB8),
                              height: 1.55)),
                      const SizedBox(height: 6),
                      // Action tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.tagBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.tagIcon, size: 11, color: s.tagTextColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(s.tagText,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: s.tagTextColor,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF6C5CE7)),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              "Tip: PDF export se apne notes kisi ko "
              "share kar sakte hain ya print kar sakte "
              "hain — note ke andar 3-dot menu se.",
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF534AB7), height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqCard(BuildContext context, List<Map<String, dynamic>> faqs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Column(
        children: List.generate(faqs.length, (i) {
          final faq = faqs[i];
          final isLast = i == faqs.length - 1;
          return Column(children: [
            InkWell(
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(12) : Radius.zero,
                bottom: isLast ? const Radius.circular(12) : Radius.zero,
              ),
              onTap: () {
                // Show answer in snackbar or expand
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(faq['answer']),
                  backgroundColor: const Color(0xFF6C5CE7),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: faq['iconBg'],
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(faq['icon'], size: 13, color: faq['iconColor']),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(faq['text'],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D2540))),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFFC4B8E0)),
                ]),
              ),
            ),
            if (!isLast)
              const Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: Color(0xFFF5F0FF),
                  thickness: 0.5),
          ]);
        }),
      ),
    );
  }
}
