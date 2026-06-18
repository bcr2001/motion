import 'package:flutter/material.dart';
import 'package:motion/motion_screens/ms_tips/tips_front.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  int? _expandedIndex;

  static const List<_FaqItem> _questions = [
    _FaqItem(
      question: AppString.faq2AccuracyMoneteringQ,
      answer: AppString.faq2AccuracyMoneteringAnswer,
      icon: Icons.timer_outlined,
    ),
    _FaqItem(
      question: AppString.faq3ForgetTimerQ,
      answer: AppString.faq3ForgetTimerAnswer,
      icon: Icons.history_toggle_off_rounded,
    ),
    _FaqItem(
      question: AppString.faq4AnyActivityQ,
      answer: AppString.faq4AnyActivityAnswer,
      icon: Icons.category_outlined,
    ),
    _FaqItem(
      question: AppString.faq5GeneralOrSpecificQ,
      answer: AppString.faq5GeneralOrSpecificAnswer,
      icon: Icons.tune_rounded,
    ),
    _FaqItem(
      question: AppString.faq6AssignToMainQ,
      answer: AppString.faq6AssignToMainAnswer,
      icon: Icons.account_tree_outlined,
    ),
    _FaqItem(
      question: AppString.faq7EFSQ,
      answer: AppString.faq7EFSAnswer,
      icon: Icons.speed_rounded,
    ),
  ];

  Widget _helpHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(
          alpha: isDarkMode ? 0.10 : 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppColor.blueMainColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 16,
                    fontweight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick answers for tracking time and organizing activities.',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _examplesShortcut(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const MainCategoriesAndSubcategoryExamples(),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColor.selfDevelopmentPieChartColor
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.view_list_outlined,
                  color: AppColor.selfDevelopmentPieChartColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subcategory Examples',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 13.5,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppString.faq1SubcategoryExamplesQ,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10.5,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionTile({
    required BuildContext context,
    required _FaqItem item,
    required int index,
  }) {
    final isExpanded = _expandedIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor = isExpanded
        ? AppColor.blueMainColor.withValues(alpha: 0.32)
        : isDarkMode
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.black12;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColor.blueMainColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColor.blueMainColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.question,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12.5,
                          fontweight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.blueGrey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(47, 12, 4, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12,
                          fontweight: FontWeight.normal,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                  sizeCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.tipsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
          children: [
            _helpHeader(context),
            const SizedBox(height: 14),
            _examplesShortcut(context),
            const SizedBox(height: 22),
            Text(
              'Frequently Asked Questions',
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 17).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < _questions.length; index++) ...[
              _questionTile(
                context: context,
                item: _questions[index],
                index: index,
              ),
              if (index != _questions.length - 1)
                const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}
