import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_firebase/firebase_services.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_reusable/mu_reusable/user_reusable.dart';
import 'package:motion/motion_reusable/mu_reusable/user_validator.dart';
import 'package:motion/motion_user/mu_reusable/mu_reuse.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signUpFormKey,
          child: SingleChildScrollView(
            // handle overflow in case the keyboard covers the fields
            child: Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top:20 ),
              child: Column(
                children: [
                  // sign up SVG,
                  SvgImage(svgImage: AppImages.signUpImage, imageAlignment: Alignment.topLeft,),

                  
                  // sign up message
                  const Center(
                    child: Text(AppString.signUpWelcomeMessage, textAlign:TextAlign.center ,style: TextStyle(
                      fontWeight: FontWeight.w600
                    ),),
                  ),

                  // continue with google widget and or widget
                  ContinueWithGoogleOr(
                    onPressed: () {},
                  ),


                  // email text field
                  TextFormFieldBuilder(
                      fieldTextEditingController: _signUpEmailController,
                      fieldHintText: AppString.emailHintText,
                      fieldValidator: FormValidator.emailValidator),

                  // password text field
                  TextFormFieldBuilder(
                    fieldTextEditingController: _signUpPasswordController,
                    fieldHintText: AppString.passwordHintText,
                    fieldValidator: FormValidator.passwordValidator,
                    fieldObscureText: true,
                  ),

                  // confirm password text field
                  TextFormFieldBuilder(
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
                      }),

                  // register button
                  AuthPageButtons(
                    onPressed: () {
                      if (_signUpFormKey.currentState!.validate()) {
                        AuthServices.signUpUser(context,
                            userEmailSignup:
                                _signUpEmailController.text.trim(),
                            userPasswordSignUp:
                                _signUpPasswordController.text.trim());
                      }
                    },
                    buttonName: AppString.registerTitle,
                  ),

                  // Sign Up Option
                  RegSignOption(
                      optionQuestion: AppString.alreadyMember,
                      optionName: AppString.logInTitle,
                      onTap: widget.toSignInPage)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
