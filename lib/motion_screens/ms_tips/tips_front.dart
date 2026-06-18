import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class MainCategoriesAndSubcategoryExamples extends StatelessWidget {
  const MainCategoriesAndSubcategoryExamples({super.key});

  static const List<_ExampleCategory> _categories = [
    _ExampleCategory(
      name: AppString.educationMainCategory,
      icon: Icons.school_outlined,
      color: AppColor.educationPieChartColor,
      examples: [
        _SubcategoryExample(
          name: AppString.lectureClassSB1,
          description: AppString.lectureClassDB1,
        ),
        _SubcategoryExample(
          name: AppString.examsSB2,
          description: AppString.examsDB2,
        ),
        _SubcategoryExample(
          name: AppString.assignmentHomeworkSB3,
          description: AppString.assignmentHomeworkDB3,
        ),
        _SubcategoryExample(
          name: AppString.studiesRevisionSB4,
          description: AppString.studiesRevisionDB4,
        ),
      ],
    ),
    _ExampleCategory(
      name: AppString.skillMainCategory,
      icon: Icons.psychology_alt_outlined,
      color: AppColor.skillsPieChartColor,
      examples: [
        _SubcategoryExample(
          name: AppString.programmingCodingSB5,
          description: AppString.programmingCodingDB5,
        ),
        _SubcategoryExample(
          name: AppString.graphicsDesignSB6,
          description: AppString.graphicsDesignDB6,
        ),
        _SubcategoryExample(
          name: AppString.languagesSB7,
          description: AppString.languagesDB7,
        ),
        _SubcategoryExample(
          name: AppString.musicSB8,
          description: AppString.musicDB8,
        ),
      ],
    ),
    _ExampleCategory(
      name: AppString.entertainmentMainCategory,
      icon: Icons.movie_filter_outlined,
      color: AppColor.entertainmentPieChartColor,
      information: AppString.entertainmentInfo,
      examples: [
        _SubcategoryExample(
          name: AppString.videoGamesSB9,
          description: AppString.videoGamesDB9,
        ),
        _SubcategoryExample(
          name: AppString.moviesAndShowsSB10,
          description: AppString.moviesAndShowsDB10,
        ),
        _SubcategoryExample(
          name: AppString.socialMediaSB11,
          description: AppString.socialMediaDB11,
        ),
      ],
    ),
    _ExampleCategory(
      name: AppString.selfDevelopmentMainCategory,
      icon: Icons.self_improvement_rounded,
      color: AppColor.selfDevelopmentPieChartColor,
      information: AppString.selfDevelopmentInfo,
      examples: [
        _SubcategoryExample(
          name: AppString.journalingSB12,
          description: AppString.journalingDB12,
        ),
        _SubcategoryExample(
          name: AppString.meditationSB13,
          description: AppString.meditationDB13,
        ),
        _SubcategoryExample(
          name: AppString.exerciseSB14,
          description: AppString.exerciseDB14,
        ),
        _SubcategoryExample(
          name: AppString.sportsSB15,
          description: AppString.sportsDB15,
        ),
      ],
    ),
    _ExampleCategory(
      name: AppString.sleepMainCategory,
      icon: Icons.bedtime_outlined,
      color: AppColor.sleepPieChartColor,
      information: AppString.sleepInfo,
      examples: [
        _SubcategoryExample(
          name: AppString.sleepSB16,
          description: AppString.sleepDB16,
        ),
        _SubcategoryExample(
          name: AppString.napSB17,
          description: AppString.nappingDB17,
        ),
      ],
    ),
  ];

  Widget _guideHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColor.selfDevelopmentPieChartColor.withValues(
          alpha: isDarkMode ? 0.10 : 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color:
                  AppColor.selfDevelopmentPieChartColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColor.selfDevelopmentPieChartColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a useful tracking list',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 15,
                    fontweight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppString.note7BackSlashAlert,
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

  Widget _categorySection({
    required BuildContext context,
    required _ExampleCategory category,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.09) : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${category.examples.length} examples',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10.5,
                          fontweight: FontWeight.normal,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (category.information != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category.information!,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),
          for (var index = 0; index < category.examples.length; index++) ...[
            _exampleRow(
              example: category.examples[index],
              accentColor: category.color,
            ),
            if (index != category.examples.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 45),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _exampleRow({
    required _SubcategoryExample example,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.name.replaceFirst(RegExp(r':\s*$'), ''),
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12.5,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example.description.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.subcategoryExampleTitles),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            _guideHeader(context),
            const SizedBox(height: 20),
            Text(
              'Category Guide',
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 17).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use these as a starting point and adapt them to your routine.',
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _categories.length; index++) ...[
              _categorySection(
                context: context,
                category: _categories[index],
              ),
              if (index != _categories.length - 1)
                const SizedBox(height: 11),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String? information;
  final List<_SubcategoryExample> examples;

  const _ExampleCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.examples,
    this.information,
  });
}

class _SubcategoryExample {
  final String name;
  final String description;

  const _SubcategoryExample({
    required this.name,
    required this.description,
  });
}
