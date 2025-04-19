import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupService {
  // API endpoint
  static const String apiUrl = 'http://182.93.94.210:3064/api/v1/register-user';
  
  // Function to register user
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // Create request body
      final Map<String, dynamic> requestBody = {
        "name": name,
        "email": email,
        "password": password,
        "phone": phone
      };
=======
import 'package:innovator/chatroom/helper.dart';
import 'package:innovator/main.dart';
>>>>>>> 154adeb1735d90fceecbdf3f308ff6d867dca70c

      // Print request for debugging
      debugPrint('Sending request to: $apiUrl');
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      // Set timeout to 60 seconds
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));
      
      // Parse and print response
      final responseData = jsonDecode(response.body);
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': responseData,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      debugPrint('Error registering user: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
<<<<<<< HEAD
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  
  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final result = await SignupService.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );
        
        setState(() {
          _isLoading = false;
        });
        
        if (result['success']) {
          _showSnackBar('User registered successfully!');
          // Navigate to home page or login page
          // Navigator.pushReplacementNamed(context, '/home');
        } else {
          final errorMsg = result['data']?['message'] ?? 'Registration failed';
          _showSnackBar(errorMsg, isError: true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('An error occurred: $e', isError: true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
=======
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(primaryColor: preciseGreen),
      child: Scaffold(
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   backgroundColor: Colors.green,
        //   centerTitle: true,
        //   title: Text('SignUp',
        //       style:
        //           TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // ),
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(76, 175, 80, 1),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  // child: Lottie.asset('animation/loginani.json',
                  //     width: mq.width * .95),
>>>>>>> 154adeb1735d90fceecbdf3f308ff6d867dca70c
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
<<<<<<< HEAD
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (with country code)',
                  border: OutlineInputBorder(),
                  hintText: '+9779845763432',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!value.startsWith('+')) {
                    return 'Please include country code (e.g., +977)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
=======
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
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: name,
                            decoration: InputDecoration(
                              labelText: 'Enter Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Enter Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            obscureText: !_isPasswordVisible,
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Enter Password',
                              prefixIcon: Icon(Icons.password),
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
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,

                            // Make the background color transparent
                            foregroundColor:
                                Colors
                                    .white, // Replace with your desired text color
                            elevation:
                                10, // Replace with your desired elevation
                            shadowColor:
                                Colors
                                    .transparent, // Replace with your desired shadow color
                            minimumSize: Size(
                              100,
                              50,
                            ), // Replace with your desired minimum size
                            maximumSize: Size(
                              200,
                              100,
                            ), // Replace with your desired maximum size
                            padding: EdgeInsets.all(
                              10,
                            ), // Replace with your desired padding
                            side: BorderSide(
                              width: 1,
                              color: Colors.transparent,
                            ), // Replace with your desired border
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ), // Replace with your desired shape
                          ),
                          onPressed: () {
                            FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text,
                                )
                                .then((userCredential) {
                                  // After creating the user, update the user's profile with the name
                                  userCredential.user?.updateProfile(
                                    displayName: name.text,
                                  );

                                  Dialogs.showSnackbar(
                                    context,
                                    'Account Has Successfully Created',
                                  );
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (_) => MainNavigationScreen(
                                  //               user: APIs.me,
                                  //             )));
                                })
                                .onError((error, stackTrace) {
                                  print("Error creating account: $error");
                                });
                            // handle login
                          },
                          label: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              letterSpacing: 1.1,
                            ),
                          ),
                          icon: Icon(Icons.person),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          label: Text(
                            'Back',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          icon: Icon(Icons.arrow_back),
                          style: ElevatedButton.styleFrom(
                            iconColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
>>>>>>> 154adeb1735d90fceecbdf3f308ff6d867dca70c
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SIGN UP', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 154adeb1735d90fceecbdf3f308ff6d867dca70c
