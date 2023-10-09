import 'package:flutter/material.dart';

import '../../motion_themes/mth_app/app_strings.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text(AppString.tipsTitle),
        centerTitle: true,
      ),
    );
  }
}
