import 'package:flutter/material.dart';
import 'package:motion/motion_screens/ms_report/report_back.dart';

import '../../motion_themes/mth_app/app_strings.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';

class NotesBeforeTheExamples extends StatelessWidget {
  const NotesBeforeTheExamples({super.key});

  // returns a Text Widget with a custom style
  Widget noteText({required String note}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        note,
        style: AppTextStyle.leadingTextLTStyle(),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // information about how to time an activity
        noteText(note: AppString.note1TrackingGuide),

        // information about what to do if you forget to start a time
        noteText(note: AppString.note2NoEstimating),

        // information about the purpose of the app
        const InfoToTheUser(
            sectionInformation: AppString.note3IndividualUseOnly),

        // information on how to maintain a concise tracking list
        noteText(note: AppString.note4ConciseTracking),

        // information about the caustion one needs to take when assigning subcategories to main categories
        noteText(note: AppString.note5subcategoryAssignment),

        // Information about the use of '/' in the Main and subcategory examples
        const InfoToTheUser(sectionInformation: AppString.note7BackSlashAlert)
      ],
    );
  }
}
