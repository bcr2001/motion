import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

import '../../motion_themes/mth_styling/app_color.dart';

// TEXT FIELD CONSTRUCTOR
typedef StringValidator = String? Function(String? value);

class TextFormFieldBuilder extends StatelessWidget {
  final String? initialValue;
  final TextEditingController? fieldTextEditingController;
  final String fieldHintText;
  final TextInputType fieldKeyboardType;
  final StringValidator? fieldValidator;
  final bool fieldObscureText;
  final InputBorder? border;
  final TextStyle? hintTextStyle;
  final int? maxCharacterLen;

  const TextFormFieldBuilder(
      {super.key,
      this.fieldTextEditingController,
      required this.fieldHintText,
      this.fieldKeyboardType = TextInputType.text,
      this.fieldValidator,
      this.fieldObscureText = false,
      this.border,
      this.hintTextStyle,
      this.maxCharacterLen,
      this.initialValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
      child: TextFormField(
        initialValue: initialValue,
        cursorColor: AppColor.blueMainColor,
        maxLength: maxCharacterLen,
        buildCounter: (BuildContext context,
                {int? currentLength, int? maxLength, bool? isFocused}) =>
            null,
        style: Theme.of(context).textTheme.bodyMedium,
        controller: fieldTextEditingController,
        keyboardType: fieldKeyboardType,
        obscureText: fieldObscureText,
        decoration: InputDecoration(
            border: border,
            contentPadding: const EdgeInsets.only(left: 5.0),
            focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColor.blueMainColor, width: 2.0)),
            hintText: fieldHintText,
            hintStyle: hintTextStyle),
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
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColor.blueMainColor, width: 2)),
          onPressed: onPressed,
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Center(
                child: Text(
              buttonName,
              style: contentStyle(
                  color: AppColor.blueMainColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            )),
          )),
    );
  }
}

// REGISTER HERE OR LOG IN OPTION
class RegSignOption2 extends StatelessWidget {
  final String regMessage;
  final String regTextSpan;
  final VoidCallback regAction;

  const RegSignOption2(
      {super.key,
      required this.regMessage,
      required this.regTextSpan,
      required this.regAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: RichText(
        text: TextSpan(
            text: regMessage,
            style: DefaultTextStyle.of(context).style,
            children: [
              // clickable text
              TextSpan(
                  text: regTextSpan,
                  style: const TextStyle(color: AppColor.blueMainColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      regAction();
                    })
            ]),
      ),
    );
  }
}

// SVG IMAGE
class SvgImage extends StatelessWidget {
  final SvgPicture svgImage;
  final AlignmentGeometry imageAlignment;

  const SvgImage(
      {super.key, required this.svgImage, required this.imageAlignment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, top: 20),
      child: Align(alignment: imageAlignment, child: svgImage),
    );
  }
}
