import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/constant/app_colors.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Prefill form with user data from AppData
    final appData = AppData();
    _nameController.text = appData.currentUserName ?? '';
    _emailController.text = appData.currentUserEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final appData = AppData();
      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/support'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${appData.authToken}',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'subject': _subjectController.text,
          'message': _messageController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = responseData['message'] ?? 'Support ticket submitted successfully';
          _nameController.clear();
          _emailController.clear();
          _subjectController.clear();
          _messageController.clear();
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to submit support ticket';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting ticket: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAQs',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    SizedBox(height: 15),
                    dropDown(
                      'How do I reset my password?',
                      'Go to the Login page and click on "Reset Password". Follow the instructions sent to your email.',
                    ),
                    dropDown(
                      'How do I contact support?',
                      'You can contact support via the Help section or email us at support@nepatronix.org.',
                    ),
                    dropDown(
                      'Where can I find my course materials?',
                      'All course materials are located under the "Courses" tab.',
                    ),
                    dropDown(
                      'Why Nepatronix is not responding?',
                      'Please ensure you have a stable internet connection and try refreshing the app.',
                    ),
                    dropDown(
                      'Why AI Math Tutor is not Giving Response?',
                      'It may be due to system updates or technical issues. Please check back later.',
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Contact Support',
                      style: TextStyle(color: Colors.black, fontSize: 23),
                    ),
                    SizedBox(height: 8),
                    name('Name', _nameController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    }),
                    SizedBox(height: 8),
                    name('Email', _emailController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    }),
                    SizedBox(height: 8),
                    name('Subject', _subjectController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    }),
                    SizedBox(height: 8),
                    name('Message', _messageController, maxLines: 3, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    }),
                    SizedBox(height: 10),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    Center(
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(AppColors.background),
                        ),
                        onPressed: _isSubmitting ? null : _submitSupportTicket,
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Submit',
                                style: TextStyle(color: Colors.black),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FloatingMenuWidget()
        ],
      ),
    );
  }

  Widget dropDown(String question, String answer, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: const Color.fromRGBO(244, 135, 6, 1),
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          backgroundColor: Colors.orangeAccent,
          title: Text(
            question,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                answer,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget name(String text, TextEditingController controller, {int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.background),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.background),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            hintText: text,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.background),
            ),
          ),
        ),
      ],
    );
  }
}