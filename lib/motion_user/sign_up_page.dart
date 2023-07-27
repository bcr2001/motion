import 'package:flutter/material.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_providers/pfp_pvd/user_pfp_provider.dart';
import 'package:motion/motion_reusable/user_pfp.dart';
import 'package:motion/motion_themes/app_images.dart';
import 'package:motion/motion_themes/app_strings.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';
import 'package:motion/motion_user/user_reusable.dart';
import 'package:motion/motion_user/user_validator.dart';
import 'package:provider/provider.dart';

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
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();

  // dispose controller to free up resources
  @override
  void dispose() {
    _userNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();

    super.dispose();
  }

  // sign up graphics
  Widget _signUpGraphics() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: AppImages.signUpImage,
        ),
      ),
    );
  }

  Widget _signUpButton({required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: blueMainColor,
          ),
          onPressed: onPressed,
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Center(
                child: Text(
              AppString.registerTitle,
              style: contentStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            )),
          )),
    );
  }

  // sign-in option
  Widget _bottomSignInOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            AppString.alreadyMember,
          ),
          GestureDetector(
            onTap: widget.toSignInPage,
            child: Text(
              AppString.logInTitle,
              style: contentStyle(color: blueMainColor),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signUpFormKey,
          child: SingleChildScrollView(
            // handle overflow in case the keyboard covers the fields
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // sign up SVG,
                  _signUpGraphics(),

                  // pfp holder and setter
                  const UserPfp(),

                  // user name text field
                  TextFormFieldBuilder(
                      fieldTextEditingController: _userNameController,
                      fieldHintText: AppString.userNameHintText,
                      fieldValidator: FormValidator.userNameValidator),

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
                          return AppString.emptyConfirmPasswordValidatorMessage;
                        } else if (value.length < 6) {
                          return AppString.invalidPasswordValidatorMessage;
                        } else if (value != _signUpPasswordController.text) {
                          return AppString.confirmNotEqual;
                        }
                        return null;
                      }),

                  // Sign In Button,
                  _signUpButton(onPressed: () {
                    if (_signUpFormKey.currentState!.validate()) {
                      AuthServices.signUpUser(context,
                          userEmailSignup: _signUpEmailController.text.trim(),
                          userPasswordSignUp:
                              _signUpPasswordController.text.trim(),
                          userName: _userNameController.text.trim(),
                          imagePfpPath: Provider.of<UserPfpProvider>(context, listen: false).imagePath);
                    }
                  }),

                  // Sign Up Option
                  _bottomSignInOption(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
