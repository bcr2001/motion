import 'package:flutter/material.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

import '../../motion_themes/mth_app/app_strings.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';

// MainCategoriesAndSubcategoryExamples is a stateless widget that displays
// examples of subcategories under their respective main categories.
class MainCategoriesAndSubcategoryExamples extends StatelessWidget {
  const MainCategoriesAndSubcategoryExamples({super.key});

  // This method creates a widget for displaying a subcategory example.
  // subcategoryName: The name of the subcategory.
  // subcategoryDescription: A brief description of the subcategory.
  Widget _subcategoryExample(
      {required String subcategoryName,
      required String subcategoryDescription}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                text: subcategoryName,
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            TextSpan(
                text: subcategoryDescription,
                style: const TextStyle(color: AppColor.tileBackgroundColor)),
          ],
        ),
      ),
    );
  }

  // This method constructs a widget for displaying a main category
  // and its associated subcategory examples.
  // mainCategoryName: The name of the main category.
  // children: A list of widgets representing subcategory examples.
  // includeAdditionalInfo: Flag to include additional information about the main category.
  // mainCategoryInfo: Additional information about the main category, if any.
  Widget _mainCategoryAndExamples(
      {required String mainCategoryName,
      required List<Widget> children,
      required bool includeAdditionalInfo,
      String mainCategoryInfo = ""}) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Displaying the main category name.
          Text(mainCategoryName, style: AppTextStyle.sectionTitleTextStyle()),

          // Conditionally displaying additional information about the main category.
          includeAdditionalInfo
              ? const SizedBox.shrink()
              : InfoToTheUser(sectionInformation: mainCategoryInfo),

          // Divider to separate the main category name from its subcategories.
          const Divider(thickness: 1.5),

          // Column containing the list of subcategory example widgets.
          Column(children: children),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Info to the user regarding the user of "/"
              const InfoToTheUser(sectionInformation: AppString.note7BackSlashAlert),

              
              // EDUCATION main category with it's examples
              _mainCategoryAndExamples(
                  mainCategoryName: AppString.educationMainCategory,
                  children: [
                    // Lecture/Classes
                    _subcategoryExample(
                        subcategoryName: AppString.lectureClassSB1,
                        subcategoryDescription: AppString.lectureClassDB1),

                    // Exams
                    _subcategoryExample(
                        subcategoryName: AppString.examsSB2,
                        subcategoryDescription: AppString.examsDB2),

                    // Assignment/ Homework
                    _subcategoryExample(
                        subcategoryName: AppString.assignmentHomeworkSB3,
                        subcategoryDescription:
                            AppString.assignmentHomeworkDB3),

                    // Studies/ Revision
                    _subcategoryExample(
                        subcategoryName: AppString.studiesRevisionSB4,
                        subcategoryDescription: AppString.studiesRevisionDB4),
                  ],
                  includeAdditionalInfo: true),

              // SKILLS main categories and subcategory examples
              _mainCategoryAndExamples(
                  mainCategoryName: AppString.skillMainCategory,
                  children: [
                    // Programming/ Coding
                    _subcategoryExample(
                        subcategoryName: AppString.programmingCodingSB5,
                        subcategoryDescription: AppString.programmingCodingDB5),

                    // Graphics Design
                    _subcategoryExample(
                        subcategoryName: AppString.graphicsDesignSB6,
                        subcategoryDescription: AppString.graphicsDesignDB6),

                    // Languages
                    _subcategoryExample(
                        subcategoryName: AppString.languagesSB7,
                        subcategoryDescription: AppString.languagesDB7),

                    // Music
                    _subcategoryExample(
                        subcategoryName: AppString.musicSB8,
                        subcategoryDescription: AppString.musicDB8)
                  ],
                  includeAdditionalInfo: true),

              // ENTERTAINMENT main category and subcategory examples
              _mainCategoryAndExamples(
                  mainCategoryName: AppString.entertainmentMainCategory,
                  children: [
                    // Video Games
                    _subcategoryExample(
                        subcategoryName: AppString.videoGamesSB9,
                        subcategoryDescription: AppString.videoGamesDB9),

                    // Movies and TvShows
                    _subcategoryExample(
                        subcategoryName: AppString.moviesAndShowsSB10,
                        subcategoryDescription: AppString.moviesAndShowsDB10),

                    // Social Media
                    _subcategoryExample(
                        subcategoryName: AppString.socialMediaSB11,
                        subcategoryDescription: AppString.socialMediaDB11),
                  ],
                  includeAdditionalInfo: false,
                  mainCategoryInfo: AppString.entertainmentInfo),

              // SELF DEVELOPMENT main category and subcategory examples
              _mainCategoryAndExamples(
                  mainCategoryName: AppString.selfDevelopmentMainCategory,
                  children: [
                    // Journaling
                    _subcategoryExample(
                        subcategoryName: AppString.journalingSB12,
                        subcategoryDescription: AppString.journalingDB12),

                    // Meditation
                    _subcategoryExample(
                        subcategoryName: AppString.meditationSB13,
                        subcategoryDescription: AppString.meditationDB13),

                    // Exercise
                    _subcategoryExample(
                        subcategoryName: AppString.exerciseSB14,
                        subcategoryDescription: AppString.exerciseDB14),

                    // Sports
                    _subcategoryExample(
                        subcategoryName: AppString.sportsSB15,
                        subcategoryDescription: AppString.sportsDB15)
                  ],
                  includeAdditionalInfo: false,
                  mainCategoryInfo: AppString.selfDevelopmentInfo),

              // SLEEP main category and subcategory example
              _mainCategoryAndExamples(
                  mainCategoryName: AppString.sleepMainCategory,
                  children: [
                    // Sleep
                    _subcategoryExample(
                        subcategoryName: AppString.sleepSB16,
                        subcategoryDescription: AppString.sleepDB16),

                    // Napping
                    _subcategoryExample(
                        subcategoryName: AppString.napSB17,
                        subcategoryDescription: AppString.nappingDB17)
                  ],
                  includeAdditionalInfo: false,
                  mainCategoryInfo: AppString.sleepInfo)
            ],
          ),
        ),
      ),
    );
  }
}
