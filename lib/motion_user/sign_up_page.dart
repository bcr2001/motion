import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:motion/motion_themes/widget_bg_color.dart';

// sign up page when I new user wants to sign up
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
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
      child: Align(
        alignment: Alignment.topLeft,
        child:
            SvgPicture.asset("assets/images/motion_icons/sign_up_graphics.svg"),
      ),
    );
  }


  // sign up button
  Widget _signUpButton({required VoidCallback onPressed}) {
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


  // sign-in option
  Widget _bottomSignInOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Are you already a member??",
            style: contentStyle(),
          ),
          GestureDetector(
            onTap: widget.toSignInPage,
            child: Text(
              " Sign In",
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
            child: Column(
              children: [
                // Graphics SVG,
                _signUpGraphics(),


                // TextFields

                  // user name text field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: TextFormField(
                    controller: _userNameController,
                    decoration:const InputDecoration(hintText: "Username"),
                  ),
                ),
                
                  // email text field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: TextFormField(
                    controller: _signUpEmailController,
                    decoration: const InputDecoration(hintText: "Email"),
                  ),
                ),

                // password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: TextFormField(
                    controller: _signUpPasswordController,
                    decoration: const InputDecoration(hintText: "Password"),
                  ),
                ),

                // confirm password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: TextFormField(
                    controller: _signUpConfirmPasswordController,
                    decoration: const InputDecoration(hintText: "Confirm Password"),
                  ),
                ),


                // Sign In Button,
                _signUpButton(onPressed: () {}),


                // Sign Up Option
                _bottomSignInOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
