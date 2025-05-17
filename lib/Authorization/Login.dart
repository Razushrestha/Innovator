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

  // Create focus nodes for email and password fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Create form key to manage AutofillGroup
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers and focus nodes when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

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

      final headers = {'Content-Type': 'application/json'};

      final response = await http.post(url, headers: headers, body: body);

      // Debug: Print full response
      log('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Parse response with proper error handling
        Map<String, dynamic>? responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          log('Error parsing response: $e');
          Dialogs.showSnackbar(context, 'Invalid response from server');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (responseData == null) {
          Dialogs.showSnackbar(context, 'Empty response from server');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Extract and validate token
        String? token;

        // Check various possible locations for the token
        if (responseData['token'] is String) {
          token = responseData['token'];
        } else if (responseData['access_token'] is String) {
          token = responseData['access_token'];
        } else if (responseData['data'] is Map &&
            responseData['data']?['token'] is String) {
          token = responseData['data']['token'];
        } else if (responseData['authToken'] is String) {
          token = responseData['authToken'];
        } else if (responseData['accessToken'] is String) {
          token = responseData['accessToken'];
        }

        log('Extracted token: $token');

        // Extract user data with null safety
        Map<String, dynamic>? userData;
        if (responseData['user'] is Map) {
          userData = Map<String, dynamic>.from(responseData['user']);
        } else if (responseData['data']?['user'] is Map) {
          userData = Map<String, dynamic>.from(responseData['data']['user']);
        }

        // Save token if available
        // Inside _loginWithAPI, after saving the token
        if (token != null && token.isNotEmpty) {
          try {
            await AppData().setAuthToken(token);
            // Verify token was saved
            final savedToken = AppData().authToken; // Synchronous getter
            log(
              'Token saved verification: ${savedToken != null ? "Success: $savedToken" : "Failed"}',
            );
            if (savedToken == null) {
              Dialogs.showSnackbar(
                context,
                'Failed to persist authentication token',
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            log('Error saving token: $e');
            Dialogs.showSnackbar(context, 'Error saving authentication token');
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        // Save user data if available
        if (userData != null) {
          try {
            await AppData().setCurrentUser(userData);
            log('User data saved successfully');
          } catch (e) {
            log('Error saving user data: $e');
            // If this is critical, we might want to show a dialog here
          }
        }

        // Trigger save of credentials for autofill
        TextInput.finishAutofillContext(shouldSave: true);

        // Navigate to home page if we have either token or user data
        if ((token != null && token.isNotEmpty) || userData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Homepage()),
          );
        } else {
          Dialogs.showSnackbar(context, 'Login response missing required data');
        }
      } else {
        // Handle error response
        Map<String, dynamic>? responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          log('Error parsing error response: $e');
        }

        final message =
            responseData?['message'] ??
            responseData?['error'] ??
            'Login failed with status ${response.statusCode}';
        Dialogs.showSnackbar(context, message.toString());
      }
    } catch (e) {
      log('Login error: $e');
      Dialogs.showSnackbar(
        context,
        'Network error. Please check your connection.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      // On failure, cancel the autofill context without saving
      if (_isLoading == false) {
        TextInput.finishAutofillContext(shouldSave: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    mq = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(primaryColor: preciseGreen),
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
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  child: Image.asset(
                    'animation/login.gif',
                    width: mq.width * .95,
                  ),
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
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10.0),
                              child: TextFormField(
                                controller: emailController,
                                focusNode: _emailFocusNode,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onEditingComplete:
                                    () => _passwordFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10.0),
                              child: TextFormField(
                                controller: passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: !_isPasswordVisible,
                                autofillHints: const [AutofillHints.password],
                                onEditingComplete: () {
                                  // This will trigger autofill save dialog in some operating systems
                                  TextInput.finishAutofillContext();
                                  // Then attempt login
                                  _loginWithAPI();
                                },
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
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
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
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        isLogin ? 'Login' : 'Sign Up',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                                shape: StadiumBorder(),
                                elevation: 1,
                              ),
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
                                    color: Colors.black,
                                    fontSize: 19,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In with ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: 'Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Cancel autofill before navigating away
                                TextInput.finishAutofillContext(
                                  shouldSave: false,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => Signup()),
                                );
                              },
                              child: Text(
                                isLogin
                                    ? 'Create new account'
                                    : 'Already have an account?',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
