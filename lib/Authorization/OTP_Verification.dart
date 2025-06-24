import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/helper/dialogs.dart';
import 'package:lottie/lottie.dart';

// OTP Verification Screen
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  
  const OTPVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> verifyOTP() async {
    // Validate inputs
    if (_otpController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter the OTP');
      return;
    }
    
    if (_newPasswordController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter a new password');
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      Dialogs.showSnackbar(context, 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API endpoint for forget password
      final url = Uri.parse('http://182.93.94.210:3066/api/v1/forget-password');
      
      // Request body
      final body = jsonEncode({
        'email': widget.email,
        'otp': _otpController.text.trim(),
        'password': _newPasswordController.text,
      });

      // Headers
      final headers = {
        'Content-Type': 'application/json',
      };

      // Debug output
      print('Request URL: $url');
      print('Request Body: $body');

      // Make POST request
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Debug output
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Process response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        Dialogs.showSnackbar(
          context, 
          responseData['message'] ?? 'Password has been reset successfully'
        );
        
        // Navigate back to login screen after short delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        var message = 'Failed to reset password. Please try again.';
        
        try {
          final responseData = jsonDecode(response.body);
          message = responseData['message'] ?? message;
        } catch (e) {
          // Parse error, use default message
        }
        
        Dialogs.showSnackbar(context, message);
      }
    } catch (e) {
      print('Error: $e');
      Dialogs.showSnackbar(context, 'Network error. Please check your connection.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API endpoint for resending OTP
      final url = Uri.parse('http://182.93.94.210:3066/api/v1/send-otp');
      
      // Request body
      final body = jsonEncode({
        'email': widget.email,
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
          responseData['message'] ?? 'OTP has been resent to your email'
        );
      } else {
        final responseData = jsonDecode(response.body);
        Dialogs.showSnackbar(
          context, 
          responseData['message'] ?? 'Failed to resend OTP. Please try again.'
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
    final mq = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromRGBO(235, 111, 70, 1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Color.fromRGBO(235, 111, 70, 1),
              width: mq.width,
              height: mq.height * 0.15,
              child: Center(
                child: Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Verification Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(235, 111, 70, 1),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We\'ve sent a verification code to',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock_outline, color: Color.fromRGBO(235, 111, 70, 1)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Color.fromRGBO(235, 111, 70, 1), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock, color: Color.fromRGBO(235, 111, 70, 1)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Color.fromRGBO(235, 111, 70, 1), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_clock, color: Color.fromRGBO(235, 111, 70, 1)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Color.fromRGBO(235, 111, 70, 1), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(235, 111, 70, 1),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : resendOTP,
                    child: Text(
                      'Didn\'t receive the code? Resend',
                      style: TextStyle(
                        color: Color.fromRGBO(235, 111, 70, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}