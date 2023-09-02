import 'package:flutter/material.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:motion/motion_reusable/sub_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class ManualTimeRecordingRoute extends StatefulWidget {
  final String subcategoryName;

  const ManualTimeRecordingRoute({super.key, required this.subcategoryName});

  @override
  State<ManualTimeRecordingRoute> createState() =>
      _ManualTimeRecordingRouteState();
}

class _ManualTimeRecordingRouteState extends State<ManualTimeRecordingRoute> {
  final _timeFormKey = GlobalKey<FormState>();

  // hours: minutes: seconds text editing contollers
  TextEditingController hourController = TextEditingController();
  TextEditingController minuteController = TextEditingController();
  TextEditingController secondController = TextEditingController();

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();

    super.dispose();
  }

  // builds the title and measurement
  Widget _titleAndTextFieldBuilder(
      {required String title,
      required TextEditingController textEditingController}) {
    return Flexible(
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(
            width: 60,
            child: TextFormFieldBuilder(
              border: InputBorder.none,
              fieldTextEditingController: textEditingController,
              fieldHintText: "00",
              fieldKeyboardType: TextInputType.number,
              hintTextStyle: TextEditingStyling.manualHintTextStyle(),
            ),
          )
        ],
      ),
    );
  }

  // seperator
  Widget _seperate() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Text(
        ":",
        style: TextEditingStyling.manualHintTextStyle(),
      ),
    );
  }

  // alert dialog that is displayed when the add icon is clicked
  void _showTimeAlertDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            insetPadding: EdgeInsets.zero,
            title: const Text(AppString.manualAddBlock),
            content: Builder(builder: (BuildContext context) {
              return SizedBox(
                height: screenHeight * 0.23,
                width: screenWidth * 0.8,
                child: Form(
                  key: _timeFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // hour:minute:second textformfield
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // hour content
                          _titleAndTextFieldBuilder(
                              title: "Hours",
                              textEditingController: hourController),

                          _seperate(),

                          // minute content
                          _titleAndTextFieldBuilder(
                              title: "Minutes",
                              textEditingController: minuteController),

                          _seperate(),

                          // seconds content
                          _titleAndTextFieldBuilder(
                              title: "Seconds",
                              textEditingController: secondController)
                        ],
                      ),

                      // cancel and add button
                      CancelAddTextButtons(
                        onPressedCancel: () {
                          navigationKey.currentState!.pop();
                          hourController.text = "";
                          minuteController.text = "";
                          secondController.text = "";
                        },
                        onPressedAdd: () {
                          logger.i("A new time block was added");
                        },
                      ),
                    ],
                  ),
                ),
              );
            }));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // the selected subcategory displayed as app bar title
        title: Text(widget.subcategoryName),
        centerTitle: true,
        actions: [
          // alert dialog to record time
          IconButton(
              onPressed: () => _showTimeAlertDialog(context),
              icon: const Icon(Icons.add))
        ],
      ),
    );
  }
}
