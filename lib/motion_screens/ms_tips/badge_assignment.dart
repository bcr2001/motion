import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import '../../motion_themes/mth_app/app_strings.dart';

// A stateless widget that displays a badge assignment table
class BadgeAssignment extends StatelessWidget {
  const BadgeAssignment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(AppString.badgeAssignmentTitle)), // AppBar title
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20.0,
                border: TableBorder.all(),
                columns: const [
                  DataColumn(
                      label: Expanded(
                    child: Text(
                      AppString.badgeNameColumn,
                      textAlign: TextAlign.center,
                    ),
                  )),
                  DataColumn(
                      label: Expanded(
                    child: Text(
                      AppString.efsRangeColumn,
                      textAlign: TextAlign.center,
                    ),
                  )),
                  DataColumn(
                      label: Expanded(
                    child: Text(
                      AppString.descriptionColumn,
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
                rows: EfsBadgePolicy.badges
                    .map(
                      (badge) => DataRow(
                        cells: [
                          DataCell(Text(badge.name)),
                          DataCell(Text(badge.rangeLabel)),
                          DataCell(Text(badge.description)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
