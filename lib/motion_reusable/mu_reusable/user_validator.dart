import 'package:motion/motion_themes/mth_app/app_strings.dart';

// TEXT FORM FIELD VALIDATOR
class FormValidator {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppString.emptyEmailValidatorMessage;
    } else {
      // Regular expression for email validation
      String pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
      RegExp regExp = RegExp(pattern);
      if (!regExp.hasMatch(value)) {
        return AppString.invalidEmailValidatorMessage;
      }
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppString.emptyPasswordValidatorMessage;
    } else if (value.length < 6) {
      return AppString.invalidPasswordValidatorMessage;
    }
    return null;
  }

  static String? subcategoryValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppString.emptySubcategoryValidatorMessage;
    } else if (value.contains(RegExp(r'[0-9]'))) {
      return AppString.subcategoryContainsNumberMessage;
    }return null;
  }
}
