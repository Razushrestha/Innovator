import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/main.dart';
import 'package:innovator/screens/Profile/Edit_Profile.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'package:innovator/widget/auth_check.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime dob;
  final String role;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? picture;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.role,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    this.picture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : DateTime.now(),
      role: json['role'] ?? '',
      level: json['level'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      picture: json['picture'],
    );
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() {
    return 'AuthException: $message';
  }
}

class UserProfileService {
  static const String baseUrl = 'http://182.93.94.210:3064/api/v1';

  // Fetch user profile using the stored token
  static Future<UserProfile> getUserProfile() async {
    // Get token from AppData
    final token = AppData().authToken;

    log(
      'Retrieved token from AppData: ${token != null ? "Token exists" : "No token found"}',
    );

    if (token == null || token.isEmpty) {
      throw AuthException('No authentication token found');
    }

    final url = Uri.parse('$baseUrl/user-profile');
    try {
      log('Sending profile request with token: Bearer $token');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      log('Profile API response status: ${response.statusCode}');
      log('Profile API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('User profile data: $data');

        // Handle both cases: data directly or nested under 'data' field
        if (data['data'] != null) {
          return UserProfile.fromJson(data['data']);
        } else {
          return UserProfile.fromJson(data);
        }
      } else if (response.statusCode == 401) {
        // Clear invalid token
        await AppData().clearAuthToken();
        throw AuthException('Authentication token expired or invalid');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching profile: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  // Upload profile picture
  static Future<String> uploadProfilePicture(File imageFile) async {
    final token = AppData().authToken;

    if (token == null || token.isEmpty) {
      throw AuthException('No authentication token found');
    }

    final filename = path.basename(imageFile.path);
    final url = Uri.parse('$baseUrl/set-avatar?filename=avatar.png');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['authorization'] = 'Bearer $token';

      // Add file to the request
      var fileStream = http.ByteStream(imageFile.openRead());
      var fileLength = await imageFile.length();

      // Determine the mime type
      String mimeType = 'image/jpeg';
      if (filename.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      var multipartFile = http.MultipartFile(
        'avatar', // field name
        fileStream,
        fileLength,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log('Avatar upload response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          return data['data']['picture'] ?? '';
        } else {
          throw Exception('Failed to get picture URL from response');
        }
      } else {
        throw Exception('Failed to upload avatar: ${response.statusCode}');
      }
    } catch (e) {
      log('Error uploading avatar: $e');
      throw Exception('Avatar upload failed: $e');
    }
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<UserProfile> _profileFuture;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = UserProfileService.getUserProfile();
  }

  // Format date to a readable string
  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final File imageFile = File(image.path);
      await UserProfileService.uploadProfilePicture(imageFile);

      // Reload profile to get updated picture
      setState(() {
        _profileFuture = UserProfileService.getUserProfile();
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Failed to upload image: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<UserProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadProfile(); // Reload profile
                            });
                          },
                          child: Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(235, 111, 70, 1),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await AppData()
                                .clearAuthToken(); // Clear token using AppData
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                          child: Text('Return to Login'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                final profile = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Stack(
                                  children: [
                                    // Profile picture
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Color.fromRGBO(
                                        235,
                                        111,
                                        70,
                                        0.2,
                                      ),
                                      backgroundImage:
                                          profile.picture != null
                                              ? NetworkImage(
                                                'http://182.93.94.210:3064${profile.picture}',
                                              )
                                              : null,
                                      child:
                                          profile.picture == null
                                              ? Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Color.fromRGBO(
                                                  235,
                                                  111,
                                                  70,
                                                  1,
                                                ),
                                              )
                                              : null,
                                    ),
                                    // Edit button overlay
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap:
                                            _isUploading
                                                ? null
                                                : _pickAndUploadImage,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color.fromRGBO(
                                              235,
                                              111,
                                              70,
                                              1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child:
                                              _isUploading
                                                  ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromRGBO(
                                          235,
                                          111,
                                          70,
                                          1,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(
                                          // Example usage in main.dart or in a router configuration
                                          MaterialPageRoute(
                                            builder:
                                                (_) => AuthCheck(
                                                  child: EditProfileScreen(),
                                                ),
                                          ),
                                        );
                                      },
                                      label: Text(
                                        'Edit Profile',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 12),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(235, 111, 70, 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Followers',
                                    style: TextStyle(
                                      color: Color.fromRGBO(235, 111, 70, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(235, 111, 70, 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Following',
                                    style: TextStyle(
                                      color: Color.fromRGBO(235, 111, 70, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(235, 111, 70, 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${profile.level.toUpperCase()} LEVEL',
                                    style: TextStyle(
                                      color: Color.fromRGBO(235, 111, 70, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ProfileInfoCard(
                        title: 'Email',
                        value: profile.email,
                        icon: Icons.email,
                      ),
                      ProfileInfoCard(
                        title: 'Phone',
                        value: profile.phone,
                        icon: Icons.phone,
                      ),
                      ProfileInfoCard(
                        title: 'Date of Birth',
                        value: formatDate(profile.dob),
                        icon: Icons.calendar_today,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ProfileInfoCard(
                        title: 'ID',
                        value: profile.id,
                        icon: Icons.fingerprint,
                      ),
                      ProfileInfoCard(
                        title: 'Role',
                        value: profile.role.toUpperCase(),
                        icon: Icons.badge,
                      ),
                      ProfileInfoCard(
                        title: 'Member Since',
                        value: formatDate(profile.createdAt),
                        icon: Icons.access_time,
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await AppData()
                                .clearAuthToken(); // Clear token using AppData
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                          child: Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(235, 111, 70, 1),
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ), // Add extra space at bottom for floating menu
                    ],
                  ),
                );
              } else {
                return Center(child: Text('No profile data found'));
              }
            },
          ),
          FloatingMenuWidget(), // Add your floating menu widget here
        ],
      ),
    );
  }
}

// Helper widget for profile information
class ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const ProfileInfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Color.fromRGBO(235, 111, 70, 1)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
