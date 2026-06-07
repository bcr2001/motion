import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../../motion_themes/mth_styling/app_color.dart';

// Page that contains the subcategory totals
class SubTotalsPage extends StatelessWidget {
  const SubTotalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.subcategoryTotalsTitle),
        centerTitle: true,
      ),
      body: const SubTotalsList(),
    );
  }
}

class SubTotalsList extends StatelessWidget {
  const SubTotalsList({super.key});

  Widget _summaryHeader({
    required BuildContext context,
    required int subcategoryCount,
    required double totalMinutes,
  }) {
    final totalTime = convertMinutesToTime(totalMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 18),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 4,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All-Time Subcategory Totals",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "$subcategoryCount subcategories tracked",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              totalTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12,
                fontweight: FontWeight.w800,
                color: AppColor.blueMainColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 10,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11,
              fontweight: FontWeight.w800,
              color: AppColor.blueMainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _subcategoryTotalCard({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> subTotalItem,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final total = (subTotalItem["total"] as num?)?.toDouble() ?? 0.0;
    final average = (subTotalItem["average"] as num?)?.toDouble() ?? 0.0;
    final convertedSubTotal = convertMinutesToTime(total);
    final convertedSubAverage = convertMinutesToHoursOnly(average);
    final convertedTotalDays = (total / 1440).toStringAsFixed(2);
    final rankColor = index < 3 ? AppColor.accountedColor : Colors.blueGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subTotalItem["subcategoryName"]?.toString() ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricChip(
                  label: "Total",
                  value: convertedSubTotal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricChip(
                  label: "Average",
                  value: convertedSubAverage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricChip(
                  label: "Days",
                  value: "$convertedTotalDays d",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubcategoryTrackerDatabaseProvider, UserUidProvider>(
        builder: (context, sub, user, child) {
      // current user uid
      final userUid = user.userUid;

      if (userUid == null) {
        return userLoadingIndicator();
      }

      return FutureBuilder(
          future: sub.retrieveAllSubcategoryTotals(currentUser: userUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColor.blueMainColor,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // returned subcategory totals
              final allSubcategoryTotals = snapshot.data ?? [];
              final totalMinutes = allSubcategoryTotals.fold<double>(
                  0.0,
                  (previousValue, item) =>
                      previousValue +
                      ((item["total"] as num?)?.toDouble() ?? 0.0));

              if (allSubcategoryTotals.isEmpty) {
                return Center(
                  child: Text(
                    AppString.informationAboutNoData,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 13,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                itemCount: allSubcategoryTotals.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _summaryHeader(
                      context: context,
                      subcategoryCount: allSubcategoryTotals.length,
                      totalMinutes: totalMinutes,
                    );
                  }

                  final subTotalItem = allSubcategoryTotals[index - 1];

                  return _subcategoryTotalCard(
                    context: context,
                    index: index - 1,
                    subTotalItem: subTotalItem,
                  );
                },
              );
            }
          });
    });
  }
}
