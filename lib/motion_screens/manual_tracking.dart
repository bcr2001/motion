import 'package:flutter/material.dart';

class ManualTimeRecordingRoute extends StatelessWidget {
  final String subcategoryName;

  const ManualTimeRecordingRoute({super.key, required this.subcategoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subcategoryName),
        centerTitle: true,
      ),
    );
  }
}
