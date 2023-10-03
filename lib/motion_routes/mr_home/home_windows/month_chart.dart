
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

class ChartPractice extends StatelessWidget {
  const ChartPractice({super.key});

  @override
  Widget build(BuildContext context) {
    BarData myBarData = BarData(
        sunAmount: 4.40,
        monAmount: 2.50,
        tueAmount: 42.42,
        wedAmount: 18.50,
        thurAmount: 100.20,
        friAmount: 88.98,
        satAmount: 96.14);

    myBarData.initializeBarData();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      height: 300,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))
          ),
          maxY: 200, 
          minY: 0,
          barGroups: myBarData.barData.map((data) => BarChartGroupData(x: data.x, barRods: [BarChartRodData(
            toY: data.y,
            color: AppColor.blueMainColor,
            width: 10, 
            borderRadius: BorderRadius.circular(4))])).toList()
        ),),
    );
  }
}

class IndivudualBars {
  final int x;
  final double y;

  IndivudualBars({required this.x, required this.y});
}

class BarData {
  final double sunAmount;
  final double monAmount;
  final double tueAmount;
  final double wedAmount;
  final double thurAmount;
  final double friAmount;
  final double satAmount;

  BarData(
      {required this.sunAmount,
      required this.monAmount,
      required this.tueAmount,
      required this.wedAmount,
      required this.thurAmount,
      required this.friAmount,
      required this.satAmount});

  List<IndivudualBars> barData = [];

  // initialize bar data
  void initializeBarData() {
    barData = [
      // sun
      IndivudualBars(x: 1, y: sunAmount),
      // mon
      IndivudualBars(x: 2, y: monAmount),
      // tue
      IndivudualBars(x: 3, y: tueAmount),
      // wed
      IndivudualBars(x: 4, y: wedAmount),
      // thur
      IndivudualBars(x: 5, y: thurAmount),
      // fri
      IndivudualBars(x: 6, y: friAmount),
      // sat
      IndivudualBars(x: 7, y: satAmount),
    ];
  }
}
