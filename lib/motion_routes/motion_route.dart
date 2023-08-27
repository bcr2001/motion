import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';

class MotionTrackRoute extends StatelessWidget {
  const MotionTrackRoute({super.key});

  // card constructor
  Widget _cardConstructor(context,
      {required cardTitle, required ListView cardListView}) {
    return 
    SizedBox(
      height: 200,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top:8.0, left: 8.0),
              child: Text(
                cardTitle,
                style: Theme.of(context).textTheme.headlineLarge,),
            ), 
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:  Divider(
                thickness: 1.5,
                color: Colors.black,),
            ),
            cardListView],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppString.motionRouteTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Consumer<AssignerProvider>(
            builder: (context, assignedList, child) {
              return ListView(
                children: [
                  // Education Category
                  _cardConstructor(
                    context,
                      cardTitle: AppString.educationMainCategory,
                      cardListView: ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, index) {}))
                ],
              );
            },
          ),
        ));
  }
}
