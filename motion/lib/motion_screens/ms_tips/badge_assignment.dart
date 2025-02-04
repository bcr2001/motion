import 'package:flutter/material.dart';
import '../../motion_themes/mth_app/app_strings.dart';


// A stateless widget that displays a badge assignment table
class BadgeAssignment extends StatelessWidget {
  const BadgeAssignment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppString.badgeAssignmentTitle)), // AppBar title
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
                rows: const [
                  DataRow(cells: [
                    DataCell(Text(AppString.timeNoviceBadge)),
                    DataCell(Text(AppString.timeNoviceRange)),
                    DataCell(Text(AppString.timeNoviceDescription)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(AppString.focusedBeginnerBadge)),
                    DataCell(Text(AppString.focusedBeginnerRange)),
                    DataCell(Text(AppString.focusedBeginnerDescription)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(AppString.timeProBadge)),
                    DataCell(Text(AppString.timeProRange)),
                    DataCell(Text(AppString.timeProDescription)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(AppString.timeMasterBadge)),
                    DataCell(Text(AppString.timeMasterRange)),
                    DataCell(Text(AppString.timeMasterDescription)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text(AppString.timeWizardBadge)),
                    DataCell(Text(AppString.timeWizardRange)),
                    DataCell(Text(AppString.timeWizardDescription)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}