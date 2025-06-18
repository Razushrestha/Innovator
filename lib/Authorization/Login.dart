import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Forget_PWD.dart';
import 'package:innovator/Authorization/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Added for FCM
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
  bool _isGoogleLoading = false;

  // Create focus nodes for email and password fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Create form key to manage AutofillGroup
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }



  // Request notification permission for FCM
  Future<void> _requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      developer.log('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      developer.log('Error requesting notification permission: $e');
    }
  }

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

      developer.log('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(response.body);
      } else {
        _handleLoginError(response);
      }
    } catch (e) {
      developer.log('Login error: $e');
      Dialogs.showSnackbar(
        context,
        'Network error. Please check your connection.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      if (!_isLoading) {
        TextInput.finishAutofillContext(shouldSave: false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Show account picker and sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Get the ID token for API authentication
        final String? idToken = await user.getIdToken(true);

        developer.log('Google Sign-In successful for user: ${user.email}');
        developer.log('User display name: ${user.displayName}');
        developer.log('User photo URL: ${user.photoURL}');
        developer.log('Firebase ID Token length: ${idToken?.length ?? 0}');

        if (idToken == null || idToken.isEmpty) {
          Dialogs.showSnackbar(context, 'Failed to get authentication token from Google');
          return;
        }

        // Try to login first, if fails then register
        bool loginSuccess = await _attemptGoogleLogin(user, idToken);

        if (!loginSuccess) {
          // If login fails, try to register the user
          bool registrationSuccess = await _attemptGoogleRegister(user, idToken);

          // If registration fails due to existing email, try login again with Firebase token
          if (!registrationSuccess) {
            developer.log('Registration failed, attempting login with Firebase token for existing user');
            bool retryLoginSuccess = await _attemptGoogleLoginForExistingUser(user, idToken);

            if (!retryLoginSuccess) {
              Dialogs.showSnackbar(
                context,
                'Unable to sign in. Please try again or contact support.',
              );
            }
          }
        }
      }
    } catch (error) {
      developer.log('Google Sign-In error: $error');
      Dialogs.showSnackbar(context, 'Google Sign-In failed: ${error.toString()}');
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  Future<bool> _attemptGoogleLoginForExistingUser(User user, String? idToken) async {
    try {
      developer.log('Attempting to login existing Google user with Firebase token');

      // First, try to get user data from your API using the Firebase token
      bool apiLoginSuccess = await _tryApiLoginWithFirebaseToken(user, idToken);
      if (apiLoginSuccess) {
        return true;
      }

      // If API login fails, save Firebase token and basic user data as fallback
      if (idToken != null && idToken.isNotEmpty) {
        try {
          await AppData().setAuthToken(idToken);
          developer.log('Firebase ID token saved to AppData successfully');

          // Create user data with proper format
          Map<String, dynamic> userData = {
            '_id': user.uid,
            'email': user.email,
            'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
            'photoURL': user.photoURL,
            'uid': user.uid,
            'isEmailVerified': user.emailVerified,
            'provider': 'google',
            'firebaseUser': true,
            'fcmTokens': [], // Initialize fcmTokens
          };

          await AppData().setCurrentUser(userData);
          developer.log('User data saved successfully with _id: ${userData['_id']}');

          // Save FCM token
          try {
            final token = await _firebaseMessaging.getToken();
            if (token != null) {
              await AppData().saveFcmToken(token);
              developer.log('FCM token saved for Google user: $token');
              final updatedUserData = AppData().currentUser;
              developer.log('Updated user data after FCM save: $updatedUserData');
            } else {
              developer.log('Failed to retrieve FCM token for Google user');
            }
          } catch (e) {
            developer.log('Error saving FCM token for Google user: $e');
          }

          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => Homepage()), (route) => false,);

          // Navigate to home page
          

          Dialogs.showSnackbar(context, 'Welcome back! Signed in with Google.');
          return true;
        } catch (e) {
          developer.log('Error saving Firebase token or user data: $e');
          Dialogs.showSnackbar(context, 'Error saving authentication data');
          return false;
        }
      } else {
        developer.log('No Firebase token available for existing user');
        return false;
      }
    } catch (e) {
      developer.log('Error in _attemptGoogleLoginForExistingUser: $e');
      return false;
    }
  }

  Future<bool> _tryApiLoginWithFirebaseToken(User user, String? idToken) async {
    try {
      developer.log('Trying API login with Firebase token for existing user');

      final url = Uri.parse('http://182.93.94.210:3064/api/v1/login');
      final body = jsonEncode({
        'email': user.email,
        'firebaseToken': idToken ?? '',
        'isExistingGoogleUser': true,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      developer.log('Existing user login request: $body');
      final response = await http.post(url, headers: headers, body: body);

      developer.log('Existing user login API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(response.body);
        return true;
      } else {
        developer.log('API login failed for existing user, will use Firebase token as fallback');
        return false;
      }
    } catch (e) {
      developer.log('Error in API login for existing user: $e');
      return false;
    }
  }

  Future<bool> _attemptGoogleLogin(User user, String? idToken) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3064/api/v1/login');

      // Try multiple request formats to see which one works
      List<Map<String, dynamic>> requestFormats = [
        {'firebaseToken': idToken ?? ''},
        {'email': user.email, 'firebaseToken': idToken ?? ''},
        {'email': user.email, 'firebaseToken': idToken ?? '', 'isGoogleLogin': true},
      ];

      for (int i = 0; i < requestFormats.length; i++) {
        final body = requestFormats[i];
        final jsonBody = jsonEncode(body);
        final headers = {'Content-Type': 'application/json'};

        developer.log('Google Login Attempt ${i + 1} Request Body: $jsonBody');
        final response = await http.post(url, headers: headers, body: jsonBody);

        developer.log('Google Login Attempt ${i + 1} API Response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          await _handleSuccessfulLogin(response.body);
          return true;
        } else if (response.statusCode != 400) {
          break;
        }
      }

      developer.log('All Google login attempts failed, will attempt registration');
      return false;
    } catch (e) {
      developer.log('Google login error: $e');
      return false;
    }
  }

  Future<bool> _attemptGoogleRegister(User user, String? idToken) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3064/api/v1/register-user');

      // Prepare registration data
      Map<String, dynamic> body = {
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'firebaseToken': idToken ?? '',
        'isGoogleSignup': true,
        'isEmailVerified': user.emailVerified,
      };

      if (user.photoURL != null) {
        body['photoURL'] = user.photoURL;
      }

      final jsonBody = jsonEncode(body);
      final headers = {'Content-Type': 'application/json'};

      developer.log('Google Register Request Body: $jsonBody');
      final response = await http.post(url, headers: headers, body: jsonBody);

      developer.log('Google Register API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _handleSuccessfulLogin(response.body);
        Dialogs.showSnackbar(context, 'Account created successfully with Google!');
        return true;
      } else if (response.statusCode == 409) {
        developer.log('Email already exists (409), will attempt login for existing user');
        return false;
      } else {
        Map<String, dynamic>? responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          developer.log('Error parsing registration error response: $e');
        }

        final message = responseData?['message'] ??
            responseData?['error']?['error'] ??
            responseData?['error'] ??
            'Registration failed with status ${response.statusCode}';
        Dialogs.showSnackbar(context, message.toString());
        return false;
      }
    } catch (e) {
      developer.log('Google registration error: $e');
      Dialogs.showSnackbar(context, 'Registration failed. Please try again.');
      return false;
    }
  }

  Future<void> _handleSuccessfulLogin(String responseBody) async {
    Map<String, dynamic>? responseData;
    try {
      responseData = jsonDecode(responseBody) as Map<String, dynamic>?;
    } catch (e) {
      developer.log('Error parsing response: $e');
      Dialogs.showSnackbar(context, 'Invalid response from server');
      return;
    }

    if (responseData == null) {
      Dialogs.showSnackbar(context, 'Empty response from server');
      return;
    }

    // Extract token
    String? token;
    if (responseData['token'] is String) {
      token = responseData['token'];
    } else if (responseData['access_token'] is String) {
      token = responseData['access_token'];
    } else if (responseData['data'] is Map && responseData['data']?['token'] is String) {
      token = responseData['data']['token'];
    } else if (responseData['authToken'] is String) {
      token = responseData['authToken'];
    } else if (responseData['accessToken'] is String) {
      token = responseData['accessToken'];
    }

    developer.log('Extracted token: ${token?.substring(0, 20)}...');

    // Extract user data
    Map<String, dynamic>? userData;
    if (responseData['user'] is Map) {
      userData = Map<String, dynamic>.from(responseData['user']);
    } else if (responseData['data'] is Map) {
      userData = Map<String, dynamic>.from(responseData['data']);
    }

    if (userData != null && !userData.containsKey('_id')) {
      if (userData.containsKey('id')) {
        userData['_id'] = userData['id'];
      } else if (userData.containsKey('userId')) {
        userData['_id'] = userData['userId'];
      } else {
        developer.log('Warning: User data missing _id field');
      }
    }

    // Save token
    if (token != null && token.isNotEmpty) {
      try {
        await AppData().setAuthToken(token);
        final savedToken = AppData().authToken;
        developer.log(
          'Token saved verification: ${savedToken != null ? "Success: ${savedToken.substring(0, 20)}..." : "Failed"}',
        );
        if (savedToken == null) {
          Dialogs.showSnackbar(context, 'Failed to persist authentication token');
          return;
        }
      } catch (e) {
        developer.log('Error saving token: $e');
        Dialogs.showSnackbar(context, 'Error saving authentication token');
        return;
      }
    }

    // Save user data
    if (userData != null) {
      try {
        // Ensure fcmTokens is initialized
        userData['fcmTokens'] ??= [];
        await AppData().setCurrentUser(userData);
        developer.log('User data saved successfully: $userData');
      } catch (e) {
        developer.log('Error saving user data: $e');
        Dialogs.showSnackbar(context, 'Error saving user data');
      }
    }

    // Save FCM token
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await AppData().saveFcmToken(token);
        developer.log('FCM token saved after login: $token');
        // Verify the save
        final updatedUserData = AppData().currentUser;
        developer.log('Updated user data after FCM save: $updatedUserData');
        if (updatedUserData?['fcmTokens']?.contains(token) == true) {
          developer.log('FCM token successfully added to fcmTokens array');
        } else {
          developer.log('Error: FCM token not found in fcmTokens array');
          Dialogs.showSnackbar(context, 'Failed to save FCM token locally');
        }
      } else {
        developer.log('Failed to retrieve FCM token');
        Dialogs.showSnackbar(context, 'Failed to retrieve FCM token');
      }
    } catch (e) {
      developer.log('Error retrieving or saving FCM token: $e');
      Dialogs.showSnackbar(context, 'Error saving FCM token: $e');
    }

    TextInput.finishAutofillContext(shouldSave: true);

    if ((token != null && token.isNotEmpty) || userData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
      );
    } else {
      Dialogs.showSnackbar(context, 'Login response missing required data');
    }
  }

  void _handleLoginError(http.Response response) {
    Map<String, dynamic>? responseData;
    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (e) {
      developer.log('Error parsing error response: $e');
    }

    final message = responseData?['message'] ??
        responseData?['error'] ??
        'Login failed with status ${response.statusCode}';
    Dialogs.showSnackbar(context, message.toString());
  }

  Future<void> _showAccountPicker() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
_handleGoogleSignIn();
      
    } catch (e) {
      developer.log('Error showing account picker: $e');
      _handleGoogleSignIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
final mq = MediaQuery.of(context).size;
  final theme = Theme.of(context);
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
                                onEditingComplete: () => _passwordFocusNode.requestFocus(),
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
                                  TextInput.finishAutofillContext();
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
                              onPressed: _isGoogleLoading ? null : _showAccountPicker,
                              icon: _isGoogleLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Lottie.asset(
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
                                TextInput.finishAutofillContext(shouldSave: false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => Signup()),
                                );
                              },
                              child: Text(
                                isLogin ? 'Create new account' : 'Already have an account?',
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