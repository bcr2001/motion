import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

import '../../motion_reusable/mu_reusable/user_reusable.dart';
import '../../motion_reusable/mu_reusable/user_validator.dart';
import '../../motion_themes/mth_styling/app_color.dart';
import '../mu_reusable/mu_reuse.dart';

// sign in screen when the user is signed out
class SignInPage extends StatefulWidget {
  final VoidCallback toSignUpPage;

  const SignInPage({super.key, required this.toSignUpPage});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // form key
  final _signInFormKey = GlobalKey<FormState>();

  // text editing controllers
  final TextEditingController _signInEmailController = TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();

  // dispose controller to free up resources
  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signInFormKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 18 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical -
                    40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgImage(
                        svgImage: AppImages.welcomeToMotionImage,
                        imageAlignment: Alignment.center,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppString.logInWelcomeMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14,
                          fontweight: FontWeight.normal,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 26),
                      ContinueWithGoogleOr(
                        onPressed: () {
                          GoogleAuthService.signInWithGoogle(context);
                        },
                      ),
                      TextFormFieldBuilder(
                        prefixIcon: Icons.email_outlined,
                        fieldTextEditingController: _signInEmailController,
                        fieldHintText: AppString.emailHintText,
                        fieldKeyboardType: TextInputType.emailAddress,
                        fieldValidator: FormValidator.emailValidator,
                      ),
                      TextFormFieldBuilder(
                        prefixIcon: Icons.lock_outline,
                        fieldTextEditingController:
                            _signInPasswordController,
                        fieldObscureText: true,
                        fieldHintText: AppString.passwordHintText,
                        fieldValidator: FormValidator.passwordValidator,
                      ),
                      AuthPageButtons(
                        buttonName: AppString.logInTitle,
                        onPressed: () {
                          if (_signInFormKey.currentState!.validate()) {
                            AuthServices.signInUser(
                              context,
                              userEmail: _signInEmailController.text.trim(),
                              userPassword:
                                  _signInPasswordController.text.trim(),
                            );
                          }
                        },
                      ),
                      RegSignOption2(
                        regMessage: AppString.areYouAMemeber,
                        regTextSpan: AppString.registerHere,
                        regAction: widget.toSignUpPage,
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
