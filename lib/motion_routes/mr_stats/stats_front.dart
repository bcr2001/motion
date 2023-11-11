import 'package:flutter/material.dart';

// the summary report of the year the user clicks on
class YearsWorthOfSummaryStatitics extends StatelessWidget {
  final String year;

  const YearsWorthOfSummaryStatitics({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(year),
      ),
    );
  }
}
