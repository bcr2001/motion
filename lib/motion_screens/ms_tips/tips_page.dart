import 'package:flutter/material.dart';
import 'package:motion/motion_screens/ms_tips/tips_front.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

import '../../motion_themes/mth_app/app_strings.dart';
import '../../motion_themes/mth_styling/app_color.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  // expansion tile that gives the answer to a faq that a user clicks on
  Widget _expandInformation(
      {required String expansionTitle, required String expansionAnswer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: ExpansionTile(
        iconColor: Colors.blueGrey,
        title: Text(
          expansionTitle,
          style:
              AppTextStyle.subSectionTextStyle(color: AppColor.accountedColor),
        ),
        children: [
          // answer to the faq
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10),
            child: Text(
              expansionAnswer,
              style: AppTextStyle.subSectionTextStyle(
                  fontsize: 13, fontweight: FontWeight.normal),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.tipsTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // (Q1) What are some examples of subcategories I can keep track of?
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const MainCategoriesAndSubcategoryExamples()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15.0, right: 15.0, top: 15, bottom: 10),
                  child: Text(
                    AppString.faq1SubcategoryExamplesQ,
                    style: AppTextStyle.subSectionTextStyle(
                        color: AppColor.accountedColor),
                  ),
                ),
              ),

              // (Q2) How can I accurately monitor my activities and track
              // time spent on each task?
              _expandInformation(
                  expansionTitle: AppString.faq2AccuracyMoneteringQ,
                  expansionAnswer: AppString.faq2AccuracyMoneteringAnswer),

              // (Q3) What should I do if I forget to start the timer when
              // initiating an activity?
              _expandInformation(
                  expansionTitle: AppString.faq3ForgetTimerQ,
                  expansionAnswer: AppString.faq3ForgetTimerAnswer),

              // (Q4) Can I track any activity using this method?
              _expandInformation(
                  expansionTitle: AppString.faq4AnyActivityQ,
                  expansionAnswer: AppString.faq4AnyActivityAnswer),

              // (Q5) Should I keep my subcategories specific or general
              //  when tracking activities?
              _expandInformation(
                  expansionTitle: AppString.faq5GeneralOrSpecificQ,
                  expansionAnswer: AppString.faq5GeneralOrSpecificAnswer),

              // (Q6) How should I assign subcategories to their respective
              // main categories?
              _expandInformation(
                  expansionTitle: AppString.faq6AssignToMainQ,
                  expansionAnswer: AppString.faq6AssignToMainAnswer),

              // (Q7) What does EFS stand for, and how is it used?
              _expandInformation(
                  expansionTitle: AppString.faq7EFSQ,
                  expansionAnswer: AppString.faq7EFSAnswer),
            ],
          ),
        ),
      ),
    );
  }
}
