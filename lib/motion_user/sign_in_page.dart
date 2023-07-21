import 'package:flutter/material.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_themes/app_images.dart';
import 'package:motion/motion_themes/app_strings.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';

import 'user_reusable.dart';
import 'user_validator.dart';

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

  // the first image displayed on the top-right
  // formless design
  Widget _signInGraphics() {
    return Align(
      alignment: Alignment.topRight,
      child: AppImages.formlessShapeImage,
    );
  }

  //second image (Welcome To Motion)
  Widget welcomeToMotion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Align(
          alignment: Alignment.topLeft, child: AppImages.welcomeToMotionImage),
    );
  }

  Widget _signInButton({required VoidCallback onPressed}) {
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
              AppString.logInTitle,
              style: contentStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            )),
          )),
    );
  }

  // multiple devices image
  Widget mulitpleDevices() {
    return Center(
      child: AppImages.devicesImage,
    );
  }

  // sign-up option
  Widget _bottomSignUpOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            AppString.areYouAMemeber,
          ),
          GestureDetector(
            onTap: widget.toSignUpPage,
            child: Text(
              AppString.registerHere,
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
          key: _signInFormKey,
          child: SingleChildScrollView(
            // Add this to handle overflow in case the keyboard covers the fields
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Graphics SVG,
                  _signInGraphics(),

                  // Welcome to motion SVG,
                  welcomeToMotion(),

                  // Email and password TextField,
                  // email text field
                  TextFormFieldBuilder(
                    fieldTextEditingController: _signInEmailController,
                    fieldHintText: AppString.emailHintText,
                    fieldKeyboardType: TextInputType.emailAddress,
                    fieldValidator: FormValidator.emailValidator
                  ),

                  // password text field
                  TextFormFieldBuilder(
                    fieldTextEditingController: _signInPasswordController,
                    fieldObscureText: true,
                    fieldHintText: AppString.passwordHintText,
                    fieldValidator: FormValidator.passwordValidator
                  ),

                  // Sign In Button,
                  _signInButton(onPressed: () {
                    if (_signInFormKey.currentState!.validate()) {
                      AuthServices.signInUser(context,
                          userEmail: _signInEmailController.text.trim(),
                          userPassword: _signInPasswordController.text.trim());
                    }
                  }),

                  // Devices svg,
                  mulitpleDevices(),

                  // Sign Up Option
                  _bottomSignUpOption(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
