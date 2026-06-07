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
  final IconData? prefixIcon;

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
      this.initialValue,
      this.prefixIcon});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          filled: true,
          fillColor: fieldColor,
          border: border,
          prefixIcon: prefixIcon == null
              ? null
              : Icon(
                  prefixIcon,
                  color: AppColor.blueMainColor,
                  size: 20,
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColor.blueMainColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          hintText: fieldHintText,
          hintStyle: hintTextStyle ??
              AppTextStyle.subSectionTextStyle(
                fontsize: 13,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
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
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.blueMainColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          buttonName,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 15,
            fontweight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: regMessage,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 13,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
            children: [
              // clickable text
              TextSpan(
                  text: regTextSpan,
                  style: const TextStyle(
                    color: AppColor.blueMainColor,
                    fontWeight: FontWeight.w800,
                  ),
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
    return Align(
      alignment: imageAlignment,
      child: SizedBox(
        height: 170,
        child: svgImage,
      ),
    );
  }
}
