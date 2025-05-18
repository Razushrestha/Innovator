import 'package:flutter/material.dart';
import 'package:innovator/screens/Profile/profile_page.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late Future<UserProfile> profile;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Date of birth
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    profile = UserProfileService.getUserProfile(); // Initialize the future
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user profile data
      final userProfile = await UserProfileService.getUserProfile();

      setState(() {
        _nameController.text = userProfile.name;
        _phoneController.text = userProfile.phone;
        _selectedDate = userProfile.dob;
        _locationController.text = "";
        _bioController.text = "";
      });
    } catch (e) {
      log('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    final debugRequest = {
      'url': 'http://182.93.94.210:3064/api/v1/set-details',
      'headers': {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppData().authToken}',
      },
      'body': jsonEncode({
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "dob": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "location": _locationController.text.trim(),
        "bio": _bioController.text.trim(),
      }),
    };
    log('FULL REQUEST: ${jsonEncode(debugRequest)}');

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = AppData().authToken;

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final Map<String, dynamic> requestData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "dob": formattedDate,
        "location": _locationController.text.trim(),
        "bio": _bioController.text.trim(),
      };

      log('Sending profile update with data: $requestData');

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/set-details'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      log('Update profile response status: ${response.statusCode}');
      log('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => UserProfileScreen()),
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['error'] ??
            errorData['message'] ??
            'Failed to update profile (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      log('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        profile = UserProfileService.getUserProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(235, 111, 70, 1),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        FutureBuilder<UserProfile>(
                          future: profile,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircleAvatar(
                                radius: 80,
                                backgroundColor: Color.fromRGBO(235, 111, 70, 0.2),
                                child: CircularProgressIndicator(
                                  color: Color.fromRGBO(235, 111, 70, 1),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const CircleAvatar(
                                radius: 80,
                                backgroundColor: Color.fromRGBO(235, 111, 70, 0.2),
                                child: Icon(
                                  Icons.error,
                                  size: 60,
                                  color: Color.fromRGBO(235, 111, 70, 1),
                                ),
                              );
                            } else if (snapshot.hasData && snapshot.data!.picture != null) {
                              return CircleAvatar(
                                radius: 80,
                                backgroundColor: Color.fromRGBO(235, 111, 70, 0.2),
                                backgroundImage: NetworkImage(
                                  'http://182.93.94.210:3064${snapshot.data!.picture}',
                                ),
                              );
                            } else {
                              return const CircleAvatar(
                                radius: 80,
                                backgroundColor: Color.fromRGBO(235, 111, 70, 0.2),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color.fromRGBO(235, 111, 70, 1),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(235, 111, 70, 1),
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(235, 111, 70, 1),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(235, 111, 70, 1),
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(235, 111, 70, 1),
                            ),
                            hintText: 'Optional',
                          ),
                        ),
                        const SizedBox(height: 16),
                        IntlPhoneField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(235, 111, 70, 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(235, 111, 70, 1),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: Color.fromRGBO(235, 111, 70, 1),
                                ),
                              ),
                              controller: TextEditingController(
                                text: DateFormat('MMMM dd, yyyy').format(_selectedDate),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your date of birth';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(235, 111, 70, 1),
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(235, 111, 70, 1),
                            ),
                            hintText: 'Optional',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(235, 111, 70, 1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const FloatingMenuWidget(),
        ], 
      ),
    );
  }
}