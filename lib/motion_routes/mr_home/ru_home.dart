import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:provider/provider.dart';

import '../../motion_core/motion_providers/sql_pvd/track_pvd.dart';

class TrackViewBuilder extends StatelessWidget {
  final List<Widget> columnChrildren;

  const TrackViewBuilder({super.key, required this.columnChrildren});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.35,
      child: Card(
        child: Column(
          children: columnChrildren,
        ),
      ),
    );
  }
}
