import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/data/app_content/app_guide_data.dart';

class AppGuideScreen extends StatefulWidget {
  const AppGuideScreen({super.key});

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
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
          const Text(AppGuideData.pageTitle,
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540))),
        ]),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? constraints.maxWidth * 0.15 : 16, 
              vertical: 20
            ),
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 40),
              
              _buildSectionTitle(AppGuideData.quickStartTitle),
              const SizedBox(height: 16),
              _buildQuickStart(isWide),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.guideTitle),
              const SizedBox(height: 16),
              ...AppGuideData.guideItems.map((item) => _buildFeatureGuideCard(item)),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.showcaseTitle),
              const SizedBox(height: 16),
              _buildFeatureShowcase(),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.tipsTitle),
              const SizedBox(height: 16),
              _buildTips(),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.troubleshootingTitle),
              const SizedBox(height: 16),
              _buildExpandableList(AppGuideData.troubleshootingItems),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.faqTitle),
              const SizedBox(height: 16),
              _buildExpandableList(AppGuideData.faqItems),
              const SizedBox(height: 40),

              _buildSectionTitle(AppGuideData.whatsNewTitle),
              const SizedBox(height: 16),
              _buildWhatsNew(),
              const SizedBox(height: 40),

              _buildNeedHelp(),
              const SizedBox(height: 40),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D2540)
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.note_alt, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            AppGuideData.heroBanner.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            AppGuideData.heroBanner.subtitle,
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppGuideData.heroBanner.chips.map((chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chip,
                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStart(bool isWide) {
    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: AppGuideData.quickStartSteps.map((step) => 
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildQuickStartCard(step, AppGuideData.quickStartSteps.indexOf(step) + 1),
            ))
          ).toList(),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: AppGuideData.quickStartSteps.length,
      itemBuilder: (context, index) {
        return _buildQuickStartCard(AppGuideData.quickStartSteps[index], index + 1);
      },
    );
  }

  Widget _buildQuickStartCard(QuickStartStep step, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, color: const Color(0xFF6C5CE7), size: 20),
              ),
              Text("Step $index", style: const TextStyle(color: Color(0xFF9B8DB8), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(step.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2540))),
              const SizedBox(height: 4),
              Text(step.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6D6380))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGuideCard(FeatureGuideItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for screenshot
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, color: Color(0xFF9B8DB8), size: 40),
                  SizedBox(height: 8),
                  Text("[ Screenshot Placeholder ]", style: TextStyle(color: Color(0xFF9B8DB8), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: const Color(0xFF6C5CE7), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2540))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(item.explanation, style: const TextStyle(fontSize: 14, color: Color(0xFF6D6380), height: 1.6)),
                if (item.tip != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFE65100)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.tip!, style: const TextStyle(fontSize: 13, color: Color(0xFFE65100), height: 1.4)),
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureShowcase() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppGuideData.showcaseItems.map((item) => 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0D9F5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16, color: const Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2540))),
            ],
          ),
        )
      ).toList(),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AppGuideData.tips.map((tip) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF0284C7)),
                const SizedBox(width: 12),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, color: Color(0xFF0C4A6E), height: 1.4))),
              ],
            ),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildExpandableList(List<ExpandableItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F0FF)),
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(items[index].title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2540))),
            iconColor: const Color(0xFF6C5CE7),
            collapsedIconColor: const Color(0xFF9B8DB8),
            shape: const Border(),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(items[index].content, style: const TextStyle(fontSize: 13, color: Color(0xFF6D6380), height: 1.5)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWhatsNew() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AppGuideData.whatsNew.version, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(AppGuideData.whatsNew.releaseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2540))),
            ],
          ),
          const SizedBox(height: 16),
          ...AppGuideData.whatsNew.features.map((feature) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature, style: const TextStyle(fontSize: 14, color: Color(0xFF6D6380)))),
                ],
              ),
            )
          ), // Fixed missing toList()
        ],
      ),
    );
  }

  Widget _buildNeedHelp() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2540),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.support_agent, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text(AppGuideData.needHelpTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email, color: Color(0xFFC4B8E0), size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppGuideData.needHelp.emailLabel, style: const TextStyle(fontSize: 12, color: Color(0xFFC4B8E0))),
                    Text(AppGuideData.needHelp.emailValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(AppGuideData.needHelp.footerText, style: const TextStyle(fontSize: 12, color: Color(0xFF9B8DB8))),
        ],
      ),
    );
  }
}
