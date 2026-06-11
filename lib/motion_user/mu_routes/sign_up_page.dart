import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:motion/motion_user/mu_reusable/mu_reuse.dart';

import '../../motion_themes/mth_styling/app_color.dart';

// sign up page when a new user wants to sign up
class SignUpPage extends StatefulWidget {
  final VoidCallback toSignInPage;

  const SignUpPage({super.key, required this.toSignInPage});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // form key
  final _signUpFormKey = GlobalKey<FormState>();

  // text editing controllers
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();

  // dispose controller to free up resources
  @override
  void dispose() {
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signUpFormKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 18 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical -
                    38,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 112,
                        child: AppImages.signUpGraphics,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppString.registerTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.sectionTitleTextStyle(
                          fontsize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppString.signUpWelcomeMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14,
                          fontweight: FontWeight.normal,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ContinueWithGoogleOr(
                        onPressed: () async {
                          await GoogleAuthService.signInWithGoogle(context);
                        },
                      ),
                      TextFormFieldBuilder(
                        prefixIcon: Icons.email_outlined,
                        fieldTextEditingController: _signUpEmailController,
                        fieldHintText: AppString.emailHintText,
                        fieldKeyboardType: TextInputType.emailAddress,
                        fieldValidator: FormValidator.emailValidator,
                      ),
                      TextFormFieldBuilder(
                        prefixIcon: Icons.lock_outline,
                        fieldTextEditingController: _signUpPasswordController,
                        fieldHintText: AppString.passwordHintText,
                        fieldValidator: FormValidator.passwordValidator,
                        fieldObscureText: true,
                      ),
                      TextFormFieldBuilder(
                        prefixIcon: Icons.verified_user_outlined,
                        fieldTextEditingController:
                            _signUpConfirmPasswordController,
                        fieldHintText: AppString.confirmPasswordHintText,
                        fieldObscureText: true,
                        fieldValidator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppString
                                .emptyConfirmPasswordValidatorMessage;
                          } else if (value.length < 6) {
                            return AppString.invalidPasswordValidatorMessage;
                          } else if (value != _signUpPasswordController.text) {
                            return AppString.confirmNotEqual;
                          }
                          return null;
                        },
                      ),
                      AuthPageButtons(
                        onPressed: () {
                          if (_signUpFormKey.currentState!.validate()) {
                            AuthServices.signUpUser(
                              context,
                              userEmailSignup:
                                  _signUpEmailController.text.trim(),
                              userPasswordSignUp:
                                  _signUpPasswordController.text.trim(),
                            );
                          }
                        },
                        buttonName: AppString.registerTitle,
                      ),
                      RegSignOption2(
                        regMessage: AppString.alreadyMember,
                        regTextSpan: AppString.logInTitle,
                        regAction: widget.toSignInPage,
                      ),
                      Center(
                        child: Container(
                          height: 4,
                          width: 52,
                          decoration: BoxDecoration(
                            color:
                                AppColor.blueMainColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
