import 'package:flutter/material.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_themes/app_images.dart';
import 'package:motion/motion_themes/app_strings.dart';

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

  // multiple devices image
  Widget mulitpleDevices() {
    return Center(
      child: AppImages.devicesImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Form(
            key: _signInFormKey,
            child: SingleChildScrollView(
              // Add this to handle overflow in case the keyboard covers the fields
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // Welcome to motion
                    SvgImage(svgImage: AppImages.welcomeToMotionImage),
        
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
                    // Log in button
                    AuthPageButtons(buttonName: AppString.logInTitle, 
                    onPressed: (){
                         if (_signInFormKey.currentState!.validate()) {
                            AuthServices.signInUser(context,
                                userEmail: _signInEmailController.text.trim(),
                                userPassword:
                                    _signInPasswordController.text.trim());
                          }
                    }),
        
                    // Devices svg,
                    mulitpleDevices(),
        
                    // Sign Up Option
                    RegSignOption(
                      onTap: widget.toSignUpPage,
                      optionQuestion: AppString.areYouAMemeber,
                      optionName: AppString.registerHere,
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
