import 'package:flutter/material.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';

// TEXT FIELD CONSTRUCTOR
typedef StringValidator = String? Function(String? value);

class TextFormFieldBuilder extends StatelessWidget {
  final TextEditingController fieldTextEditingController;
  final String fieldHintText;
  final TextInputType fieldKeyboardType;
  final StringValidator fieldValidator;
  final bool fieldObscureText;

  const TextFormFieldBuilder(
      {super.key,
      required this.fieldTextEditingController,
      required this.fieldHintText,
      this.fieldKeyboardType = TextInputType.text,
      required this.fieldValidator,
      this.fieldObscureText = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
      child: TextFormField(
        controller: fieldTextEditingController,
        keyboardType: fieldKeyboardType,
        obscureText: fieldObscureText,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(left: 5.0),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: blueMainColor, width: 2.0)),
          hintText: fieldHintText,
        ),
        validator: fieldValidator,
      ),
    );
  }
}