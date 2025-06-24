import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Authorization/OTP_Verification.dart';
import 'package:innovator/helper/dialogs.dart';

class Forgot_PWD extends StatefulWidget {
  const Forgot_PWD({super.key});

  @override
  State<Forgot_PWD> createState() => _Forgot_PWDState();
}

class _Forgot_PWDState extends State<Forgot_PWD> {
  TextEditingController email = TextEditingController();
  bool _isLoading = false;

  Future<void> sendOTP() async {
    if (email.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API endpoint
      final url = Uri.parse('http://182.93.94.210:3066/api/v1/send-otp');
      
      // Request body
      final body = jsonEncode({
        'email': email.text.trim(),
      });

      // Headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Make POST request
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Process response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        Dialogs.showSnackbar(
          context, 
          responseData['message'] ?? 'OTP has been sent to your email'
        );
        
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPVerificationScreen(email: email.text)),
        );
      } else {
        final responseData = jsonDecode(response.body);
        Dialogs.showSnackbar(
          context, 
          responseData['message'] ?? 'Failed to send OTP. Please try again.'
        );
      }
    } catch (e) {
      Dialogs.showSnackbar(context, 'Network error. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2.0,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(235, 111, 70, 1),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(70)),
            ),
            // child: Padding(
            //   padding: EdgeInsets.only(bottom: mq.height * 0.15),
            //   child: Center(
            //     child: Lottie.asset(
            //       'animation/forgot_password.json',  // Add a suitable animation asset
            //       width: mq.width * .6,
            //     ),
            //   ),
            // ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(235, 111, 70, 1),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Enter your email to receive a verification code',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter Email',
                        prefixIcon: Icon(Icons.email, color: Color.fromRGBO(235, 111, 70, 1)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Color.fromRGBO(235, 111, 70, 1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Color.fromRGBO(235, 111, 70, 1), width: 2),
                        ),
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Color.fromRGBO(235, 111, 70, 1)),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : sendOTP,
                      label: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Send Verification Code',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(235, 111, 70, 1),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      icon: Icon(Icons.send, color: Colors.white),
                    ),
                    SizedBox(height: 15),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back, color: Color.fromRGBO(235, 111, 70, 1)),
                      label: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color.fromRGBO(235, 111, 70, 1),
                          fontSize: 14,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

