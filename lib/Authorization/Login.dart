import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:innovator/Authorization/signup.dart';
import 'package:innovator/chatroom/helper.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Inner_Homepage.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../chatroom/api/api.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color preciseGreen = Color.fromRGBO(76, 175, 80, 1);
  bool _isPasswordVisible = false;

  bool isLogin = true;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  _handlegooglebtnclick() {
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAddtionalInfo: ${user.additionalUserInfo}');

        if ((await APIs.userExists())) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => Homepage(user: APIs.me,
                      )));
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => Homepage(user: APIs.me,
                         
                        )));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
  try {
    // Check internet connection
    await InternetAddress.lookup('google.com');
    
    // Initialize GoogleSignIn
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      signInOption: SignInOption.standard,
    );

    // Sign out first to ensure account picker appears
    await googleSignIn.signOut();
    
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      return null; // User canceled the sign-in
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    log('\n_signInWithGoogle: $e');
    Dialogs.showSnackbar(context, 'Something Went Wrong (Check Internet!)');
    return null;
  }
}

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    mq = MediaQuery.of(context).size;
    // final mq = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(
        primaryColor: preciseGreen,
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            isLogin ? 'Login' : 'Sign Up',
            style: TextStyle(color: Color.fromARGB(255, 233, 238, 241)),
          ),
          backgroundColor: Color.fromRGBO(76, 175, 80, 1),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(76, 175, 80, 1),
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(70)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  child: Lottie.asset('animation/loginani.json',
                      width: mq.width * .95),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email)),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            obscureText: !_isPasswordVisible,
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.password_sharp),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons
                                          .visibility, // Change icon based on visibility
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            //obscureText: true,
                          ),
                        ),
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: TextButton(
                        //     onPressed: (() => Get.to(Forgot_PWD())),
                        //     child: Text(
                        //       'Forgot Password ?',
                        //       style: TextStyle(fontSize: 15),
                        //     ),
                        //   ),
                        // ),
                        ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 10,
    shadowColor: Colors.transparent,
    minimumSize: const Size(200, 50),
    maximumSize: const Size(200, 100),
    padding: const EdgeInsets.all(10),
    side: const BorderSide(
      width: 1,
      color: Colors.transparent,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
 // In your login button's onPressed:
onPressed: () async {
  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
    Dialogs.showSnackbar(context, 'Please enter both email and password');
    return;
  }

  try {
    Dialogs.showProgressBar(context);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    
    Navigator.pop(context); // Hide loading
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Homepage(user: APIs.me,)),
    );
  } on FirebaseAuthException catch (e) {
    Navigator.pop(context); // Hide loading
    String errorMessage = 'Login failed';
    
    if (e.code == 'wrong-password') {
      errorMessage = 'Incorrect password';
    } else if (e.code == 'user-not-found') {
      errorMessage = 'No user found with this email';
    } else if (e.code == 'too-many-requests') {
      errorMessage = 'Account temporarily locked. Try again later';
    }
    
    Dialogs.showSnackbar(context, errorMessage);
  } catch (e) {
    Navigator.pop(context);
    Dialogs.showSnackbar(context, 'Login error: ${e.toString()}');
  }
},
  child: Text(
    isLogin ? 'Login' : 'Sign Up',
    style: const TextStyle(
      fontSize: 16,
      letterSpacing: 1.1,
    ),
  ),
),
                        // ElevatedButton(
                        //     onPressed: () {
                        //       Navigator.push(context,
                        //           MaterialPageRoute(builder: (_) => Phoneauth()));
                        //     },
                        //     child: Text('Phone number')),
                        SizedBox(
                          height: 10,
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: StadiumBorder(),
                              elevation: 1),
                          onPressed: () {
                            _handlegooglebtnclick();
                          },
                          icon: Lottie.asset(
                            'animation/Googlesignup.json',
                            height: mq.height * .05,
                          ),
                          label: RichText(
                              text: const TextSpan(
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 19),
                                  children: [
                                TextSpan(text: 'Sign In with '),
                                TextSpan(
                                    text: 'Google',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500))
                              ])),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context, //
                                MaterialPageRoute(builder: (_) => SignupPage()));
                          },
                          child: Text(
                            isLogin
                                ? 'Create new account'
                                : 'Already have an account?',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

