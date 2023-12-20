import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_core/mc_firebase/google_services.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import '../../motion_reusable/mu_reusable/user_reusable.dart';
import '../../motion_reusable/mu_reusable/user_validator.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signInFormKey,
          child: SingleChildScrollView(
            // Add this to handle overflow in case the keyboard covers the fields
            child: Container(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 50),
              child: Column(
                children: [
                  // Welcome to motion
                  SvgImage(
                    svgImage: AppImages.welcomeToMotionImage,
                    imageAlignment: Alignment.center,
                  ),

                  // welcome message
                   Center(
                    child: Text(
                      AppString.logInWelcomeMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.special1SectionTitleTextStyle(),
                    ),
                  ),
                  // continue with google widget and or widget
                  ContinueWithGoogleOr(
                    onPressed: () {
                      GoogleAuthService.signInWithGoodle(context);
                    },
                  ),

                  // Email and password TextField,
                  // email text field
                  TextFormFieldBuilder(
                      fieldTextEditingController: _signInEmailController,
                      fieldHintText: AppString.emailHintText,
                      fieldKeyboardType: TextInputType.emailAddress,
                      fieldValidator: FormValidator.emailValidator),

                  // password text field
                  TextFormFieldBuilder(
                      fieldTextEditingController: _signInPasswordController,
                      fieldObscureText: true,
                      fieldHintText: AppString.passwordHintText,
                      fieldValidator: FormValidator.passwordValidator),

                  // Log in button
                  AuthPageButtons(
                      buttonName: AppString.logInTitle,
                      onPressed: () {
                        if (_signInFormKey.currentState!.validate()) {
                          AuthServices.signInUser(context,
                              userEmail: _signInEmailController.text.trim(),
                              userPassword:
                                  _signInPasswordController.text.trim());
                        }
                      }),

                  // Sign Up Option
                  RegSignOption2(
                      regMessage: AppString.areYouAMemeber,
                      regTextSpan: AppString.registerHere,
                      regAction: widget.toSignUpPage)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
