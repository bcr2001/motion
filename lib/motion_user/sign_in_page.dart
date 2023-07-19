import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motion/motion_core/firebase_services.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';

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

  // sign in graphics
  Widget _signInGraphics() {
    return Align(
      alignment: Alignment.topRight,
      child:
          SvgPicture.asset("assets/images/motion_icons/sign_in_graphics.svg"),
    );
  }

  //welcome svg
  Widget welcomeToMotion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Align(
          alignment: Alignment.topLeft,
          child:
              SvgPicture.asset("assets/images/motion_icons/welcome_back.svg")),
    );
  }

  // sign in button
  Widget _signInButton({required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
              "Sign in",
              style: contentStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
            )),
          )),
    );
  }

  // multiple devices svg
  Widget mulitpleDevicesSvg() {
    return Center(
      child: Column(
        children: [
          SvgPicture.asset("assets/images/motion_icons/devices.svg"),
          Text(
            "*motion on other devices coming soon!!",
            style: contentStyle(fontSize: 11, color: Colors.black),
          )
        ],
      ),
    );
  }

  // sign-up option
  Widget _bottomSignUpOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Are you not a member?",
            style: contentStyle(),
          ),
          GestureDetector(
            onTap: widget.toSignUpPage,
            child: Text(
              " Register Here",
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
            child: Column(
              children: [
                // Graphics SVG,
                _signInGraphics(),

                // Welcome to motion SVG,
                welcomeToMotion(),

                // Email and password TextField,
                // email text field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: TextFormField(
                    controller: _signInEmailController,
                    decoration: const InputDecoration(hintText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "please enter an email";
                      } else {
                        // Regular expression for email validation
                        String pattern =
                            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
                        RegExp regExp = RegExp(pattern);
                        if (!regExp.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                ),

                // password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextFormField(
                    controller: _signInPasswordController,
                    decoration: const InputDecoration(hintText: "Password"),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "please enter a password";
                      } else if (value.length < 6) {
                        return "password must be more than 6 characters long";
                      }
                      return null;
                    },
                  ),
                ),

                // Sign In Button,
                _signInButton(onPressed: () {
                  if(_signInFormKey.currentState!.validate()){
                    AuthServices.signInUser(context, userEmail: _signInEmailController.text.trim(), userPassword: _signInPasswordController.text.trim());
                  }
                }),

                // Devices svg,
                mulitpleDevicesSvg(),

                // Sign Up Option
                _bottomSignUpOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
