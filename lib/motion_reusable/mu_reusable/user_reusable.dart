import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';

// TEXT FIELD CONSTRUCTOR
typedef StringValidator = String? Function(String? value);

class TextFormFieldBuilder extends StatelessWidget {
  final TextEditingController fieldTextEditingController;
  final String fieldHintText;
  final TextInputType fieldKeyboardType;
  final StringValidator? fieldValidator;
  final bool fieldObscureText;
  final InputBorder? border;
  final TextStyle? hintTextStyle;
  final int? maxCharacterLen;


  const TextFormFieldBuilder(
      {super.key,
      required this.fieldTextEditingController,
      required this.fieldHintText,
      this.fieldKeyboardType = TextInputType.text,
      this.fieldValidator,
      this.fieldObscureText = false, this.border, this.hintTextStyle, this.maxCharacterLen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
      child: TextFormField(
        maxLength: maxCharacterLen,
        buildCounter: (BuildContext context,
                {int? currentLength, int? maxLength, bool? isFocused}) =>
            null,
        style: Theme.of(context).textTheme.headlineLarge,
        controller: fieldTextEditingController,
        keyboardType: fieldKeyboardType,
        obscureText: fieldObscureText,
        decoration: InputDecoration(
          border: border,
          contentPadding: const EdgeInsets.only(left: 5.0),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: blueMainColor, width: 2.0)),
          hintText: fieldHintText,
          hintStyle: hintTextStyle
        ),
        validator: fieldValidator,
      ),
    );
  }
}

// SIGN IN AND SIGN OUT PAGE BUTTON BUILDER
class AuthPageButtons extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonName;

  const AuthPageButtons(
      {super.key, required this.buttonName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: OutlinedButton(
          onPressed: onPressed,
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Center(
                child: Text(
              buttonName,
              style: contentStyle(
                  color: blueMainColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            )),
          )),
    );
  }
}

// REGISTER HERE OR LOG IN OPTION
class RegSignOption extends StatelessWidget {
  final String optionQuestion;
  final String optionName;
  final VoidCallback onTap;

  const RegSignOption(
      {super.key,
      required this.optionQuestion,
      required this.optionName,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            optionQuestion,
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              optionName,
              style: contentStyle(color: blueMainColor),
            ),
          )
        ],
      ),
    );
  }
}

// SVG IMAGE
class SvgImage extends StatelessWidget {
  final SvgPicture svgImage;

  const SvgImage({super.key, required this.svgImage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Align(alignment: Alignment.topLeft, child: svgImage),
    );
  }
}
