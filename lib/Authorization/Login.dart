import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:innovator/Authorization/Forget_PWD.dart';
import 'package:innovator/Authorization/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:innovator/helper/dialogs.dart';
import 'package:innovator/innovator_home.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color preciseGreen = Color.fromRGBO(235, 111, 70, 1);
  bool _isPasswordVisible = false;

  bool isLogin = true;
  bool _isLoading = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _loginWithAPI() async {
  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
    Dialogs.showSnackbar(context, 'Please enter both email and password');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final url = Uri.parse('http://182.93.94.210:3064/api/v1/login');
    final body = jsonEncode({
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
    });

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    // Debug: Print full response
    log('API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // More detailed token extraction logic
      String? token;
      
      // Check various possible locations for the token
      if (responseData['token'] != null) {
        token = responseData['token'];
      } else if (responseData['access_token'] != null) {
        token = responseData['access_token'];
      } else if (responseData['data'] != null && responseData['data']['token'] != null) {
        token = responseData['data']['token'];
      } else if (responseData['authToken'] != null) {
        token = responseData['authToken'];
      } else if (responseData['accessToken'] != null) {
        token = responseData['accessToken'];
      }

      log('Extracted token: $token');
      
      if (token != null && token.isNotEmpty) {
        await AppData().setAuthToken(token);
        
        // Verify token was saved
        final savedToken = await AppData().authToken;
        log('Token saved verification: ${savedToken != null ? "Success" : "Failed"}');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Homepage()),
        );
      } else {
        log('Token not found in response. Full response: ${response.body}');
        Dialogs.showSnackbar(context, 'Login successful but no token received');
        
        // As a fallback, check if there's user data that might indicate success
        if (responseData['user'] != null || responseData['data'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        } else {
          Dialogs.showSnackbar(context, 'Login failed - no token or user data received');
        }
      }
    } else {
      final responseData = jsonDecode(response.body);
      final message = responseData['message'] ?? 
                     responseData['error'] ?? 
                     'Login failed with status ${response.statusCode}';
      Dialogs.showSnackbar(context, message);
    }
  } catch (e) {
    log('Login error: $e');
    Dialogs.showSnackbar(context, 'Network error. Please check your connection.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

//   _handleGoogleBtnClick() {
//   Dialogs.showProgressBar(context);
//   _signInWithGoogle().then((user) async {
//     Navigator.pop(context);
//     if (user != null) {
//       log('\nUser: ${user.user}');
//       log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

//       // Generate and save token to AppData
//       final String token = await _generateLocalToken(user);
//       await AppData().setAuthToken(token);
      
//       // Save user data to AppData
//       final userData = {
//         'id': user.user?.uid,
//         'email': user.user?.email,
//         'name': user.user?.displayName,
//         'photoUrl': user.user?.photoURL,
//         'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
//       };
//       await AppData().setCurrentUser(userData);

//       if ((await APIs.userExists())) {
//         // User exists, navigate directly to the Inner homepage
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => Homepage())
//         );
//       } else {
//         // Create new user and then navigate
//         await APIs.createUser().then((value) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => Homepage())
//           );
//         });
//       }
//     }
//   });
// }

// // Modified Google Sign-In method with improved error handling
// Future<UserCredential?> _signInWithGoogle() async {
//   try {
//     // Check internet connection
//     await InternetAddress.lookup('google.com');
    
//     // Initialize GoogleSignIn with web client ID
//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       scopes: ['email', 'profile'],
//     );

//     // Sign out first to ensure account picker appears
//     await googleSignIn.signOut();
    
//     // Try silent sign-in first for bette r user experience
//     GoogleSignInAccount? googleUser;
//     try {
//       googleUser = await googleSignIn.signInSilently();
//     } catch (e) {
//       log('Silent sign-in failed, proceeding with interactive sign-in: ${e.toString()}');
//     }
    
//     // If silent sign-in failed, try interactive sign-in
//     if (googleUser == null) {
//       try {
//         googleUser = await googleSignIn.signIn();
//       } catch (e) {
//         log('Interactive sign-in failed: ${e.toString()}');
        
//         // Detailed error logging for debugging
//         if (e is PlatformException) {
//           log('Error code: ${e.code}');
//           log('Error message: ${e.message}');
//           log('Error details: ${e.details}');
//         }
        
//         throw e; // Re-throw for general error handling
//       }
//     }
    
//     if (googleUser == null) {
//       log('Sign-in canceled by user');
//       return null; // User canceled the sign-in
//     }

//     // Obtain the auth details from the request
//     final GoogleSignInAuthentication googleAuth = 
//         await googleUser.authentication;

//     // Create a new credential
//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     // Once signed in, return the UserCredential
//     return await FirebaseAuth.instance.signInWithCredential(credential);
//   } catch (e) {
//     log('\n_signInWithGoogle error: $e');
    
//     // Show more specific error message based on common error codes
//     if (e.toString().contains('10:')) {
//       Dialogs.showSnackbar(context, 'Google Sign-In failed. Check your Google Services configuration.');
//     } else if (e.toString().contains('network_error')) {
//       Dialogs.showSnackbar(context, 'Network error. Please check your internet connection.');
//     } else {
//       Dialogs.showSnackbar(context, 'Sign-In failed. Please try again later.');
//     }
//     return null;
//   }
// }

// // Generate a local token based on user credentials
// Future<String> _generateLocalToken(UserCredential user) async {
//   try {
//     // Get Firebase ID token as base for our local token
//     final idToken = await user.user?.getIdToken();
    
//     // Create simplified token structure with important user data
//     final tokenData = {
//       'userId': user.user?.uid,
//       'email': user.user?.email,
//       'name': user.user?.displayName,
//       'issuedAt': DateTime.now().millisecondsSinceEpoch,
//       'expiresAt': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
//     };
    
//     // Encode as base64 - this is a simple token implementation
//     final jsonData = jsonEncode(tokenData);
//     final bytes = utf8.encode(jsonData);
//     final token = base64Encode(bytes);
    
//     log('Generated local token for user: ${user.user?.email}');
//     return token;
//   } catch (e) {
//     log('Error generating local token: $e');
//     // Return a simple fallback token with limited data
//     return base64Encode(utf8.encode(jsonEncode({
//       'userId': user.user?.uid,
//       'fallback': true,
//       'issuedAt': DateTime.now().millisecondsSinceEpoch
//     })));
//   }
// }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    mq = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(
        primaryColor: preciseGreen,
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          
          backgroundColor: Color.fromRGBO(244, 135, 6, 1),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(244, 135, 6, 1),
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(70)),
                    
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  child: Image.asset('animation/login.gif',
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
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (() => Get.to(Forgot_PWD())),
                            child: Text(
                              'Forgot Password ?',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(244, 135, 6, 1),
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
                          onPressed: _isLoading ? null : _loginWithAPI,
                          child: _isLoading 
                              ? SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(color: Colors.white)
                                )
                              : Text(
                                  isLogin ? 'Login' : 'Sign Up',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                              shape: StadiumBorder(),
                              elevation: 1),
                          onPressed: () {
                            //_handleGoogleBtnClick();
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
                                TextSpan(text: 'Sign In with ',style: TextStyle(color: Colors.white)),
                                TextSpan(
                                    text: 'Google',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500))
                              ])),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => Signup()));
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