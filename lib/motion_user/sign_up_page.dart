import 'package:flutter/material.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_providers/pfp_pvd/user_pfp_provider.dart';
import 'package:motion/motion_reusable/user_pfp.dart';
import 'package:motion/motion_themes/app_images.dart';
import 'package:motion/motion_themes/app_strings.dart';
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
                  SvgImage(svgImage: AppImages.signUpImage),

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

                  // register button
                  AuthPageButtons(
                    onPressed: () {
                      if (_signUpFormKey.currentState!.validate()) {
                        AuthServices.signUpUser(context,
                            userEmailSignup: _signUpEmailController.text.trim(),
                            userPasswordSignUp:
                                _signUpPasswordController.text.trim(),
                            userName: _userNameController.text.trim(),
                            imagePfpPath: Provider.of<UserPfpProvider>(context,
                                    listen: false)
                                .imagePath);
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
