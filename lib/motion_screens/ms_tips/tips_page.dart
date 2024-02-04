import 'package:flutter/material.dart';
import 'package:motion/motion_routes/mr_home/home_reusable/back_home.dart';
import 'package:motion/motion_screens/ms_tips/tips_front.dart';

import '../../motion_themes/mth_app/app_strings.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.tipsTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // page title
              sectionTitle(titleName: AppString.tipsImportantNoteTitle),
        
              // notes before examples: Contains important information the user should know about 
              // how the app should be used
               const NotesBeforeTheExamples()
            ],
          ),
        ),
      ),
    );
  }
}
