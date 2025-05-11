import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/helper/dialogs.dart';
import 'package:innovator/main.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _isPasswordVisible = false;
  final Color preciseGreen = const Color.fromRGBO(244, 135, 6, 1);
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  String completePhoneNumber = '';
  bool isLoading = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Pre-filling the form with the provided data for testing
    nameController.text = "";
    emailController.text = "";
    passwordController.text = "";
    completePhoneNumber = "";
    dobController.text = "";
    // Parse the date from the string format YYYY-MM-DD
    final dateParts = "2005-08-08".split('-');
    if (dateParts.length == 3) {
      selectedDate = DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  // Format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month < 10 ? '0${date.month}' : date.month.toString();
    String day = date.day < 10 ? '0${date.day}' : date.day.toString();
    return '$year-$month-$day';
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: preciseGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = formatDate(picked);
      });
    }
  }

  // Validate form fields
  bool validateFields() {
    if (nameController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      Dialogs.showSnackbar(context, 'Please enter a valid email');
      return false;
    }
    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      Dialogs.showSnackbar(context, 'Password must be at least 6 characters');
      return false;
    }
    if (completePhoneNumber.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your phone number');
      return false;
    }
    if (dobController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your date of birth');
      return false;
    }
    return true;
  }

  Future<void> signUp() async {
    if (!validateFields()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Create request body for API
      final Map<String, dynamic> requestBody = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "phone": completePhoneNumber,
        "dob": dobController.text // Adding the DOB field
      };

      // Make API call
      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/register-user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully registered
        final responseData = jsonDecode(response.body);
        
        // You might want to store user info or token here
        // For example, if the API returns a user object or token:
        // final user = responseData['user'];
        // final token = responseData['token'];
        // Save these to shared preferences or other storage

        Dialogs.showSnackbar(context, 'Account successfully created');
        
        // Navigate to home page
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => LoginPage(),
        ));
      } else {
        // Registration failed
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Registration failed';
        Dialogs.showSnackbar(context, errorMessage);
      }
    } catch (e) {
      Dialogs.showSnackbar(context, 'Error creating account: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: preciseGreen,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: preciseGreen, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Top green container
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(	244, 135, 6, 1),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(70)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: Center(
                  child: Image.asset('animation/signup.gif',
                      width: mq.width * .95),
                ),
              ),
            ),
            
            // White container with form
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.6, // Slightly larger to accommodate the new field
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
                        const SizedBox(height: 20),
                        
                        // Name field
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(

                            labelText: 'Enter Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Email field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Enter Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Phone number field with country code picker
                        IntlPhoneField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          initialCountryCode: 'NP', // Changed to Nepal
                          onChanged: (phone) {
                            completePhoneNumber = phone.completeNumber;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Date of Birth field
                        TextField(
                          controller: dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.date_range),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          onTap: () => _selectDate(context),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextField(
                          obscureText: !_isPasswordVisible,
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Enter Password',
                            prefixIcon: const Icon(Icons.lock),
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
                        
                        const SizedBox(height: 32),
                        
                        // Sign up button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            minimumSize: const Size(200, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : signUp,
                          icon: isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add),
                          label: Text(
                            isLoading ? 'Creating Account...' : 'Sign Up',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Back button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  LoginPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Login'),
                          style: TextButton.styleFrom(
                            foregroundColor: preciseGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Show loading indicator if needed
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}