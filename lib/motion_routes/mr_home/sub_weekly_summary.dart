import 'package:flutter/material.dart';

class SubcategoryWeeklySummary extends StatefulWidget {
  const SubcategoryWeeklySummary({super.key});

  @override
  State<SubcategoryWeeklySummary> createState() =>
      _SubcategoryWeeklySummaryState();
}

class _SubcategoryWeeklySummaryState extends State<SubcategoryWeeklySummary> {
  final _pageController = PageController();
  double _initialPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _initialPage = _pageController.page!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.35,
      child: Card(
        child: PageView(
          controller: _pageController,
          onPageChanged: (value) {
            setState(() {
              _initialPage = value.toDouble();
            });
          },
          children:const [
            Text("Week 1"),
            Text("Week 2"),
            Text("Week 3"),
            Text("Week 4"),
          ],
        ),
      ),
    );
  }
}
