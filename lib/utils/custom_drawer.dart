import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/Course/homepage.dart';
import 'package:innovator/screens/Profile/profile_page.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      // Use AuthToken from AppData singleton
      final String? authToken = AppData().authToken;
      
      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          setState(() {
            _userData = responseData['data'];
            _isLoading = false;
            
            // Optionally update the current user data in AppData if needed
            AppData().setCurrentUser(_userData!);
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Unknown error';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEB6B46),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: DrawerHeader(
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: const Color(0xFFEB6B46),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _buildProfileHeader(),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerTile(Icons.book, 'Courses', () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ProviderScope(child: Course_Homepage())), (route) => false);}), // Navigate to Course_Homepage
          _buildDrawerTile(Icons.star, 'Messages', () {}),
          _buildDrawerTile(Icons.message, 'Profile', () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => ProviderScope(child: UserProfileScreen())), (route) => false);}),
          _buildDrawerTile(Icons.settings, 'Settings', () {}),
          _buildDrawerTile(Icons.privacy_tip_rounded, 'Privacy&Policy', () {}),
          _buildDrawerTile(Icons.question_answer_rounded, 'F&Q', () {}),
          const Divider(thickness: 1, indent: 20, endIndent: 20),
          _buildDrawerTile(
            Icons.logout, 
            'Logout', 
            ()  {


              showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout Confirmation ↪️'),
            content: const Text(
              'Are you sure you want to logout?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                  await AppData().clearAuthToken();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
              // You would typically navigate to login screen here
              // Navigator.of(context).pushReplacementNamed('/login');
            }
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Text(
              'Innovator App v1.0\nPowered by Nepatronix',
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Try to use AppData().currentUser first if available
    final userData = AppData().currentUser ?? _userData;
    
    final String name = userData?['name'] ?? 'User';
    final String level = (userData?['level'] ?? 'user').toString().toUpperCase();
    final String email = userData?['email'] ?? '';
    final String? picturePath = userData?['picture'];
    final String baseUrl = 'http://182.93.94.210:3064'; // Base URL for the API

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: picturePath != null
              ? NetworkImage('$baseUrl$picturePath')
              : const Icon(Icons.person, size: 40,) as ImageProvider,
        ),
        //const SizedBox(height: 10),
        Text(
          'Welcome, ',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          '$name ',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        // Text(
        //   level,
        //   style: const TextStyle(
        //     color: Colors.white70,
        //     fontSize: 14,
        //     fontStyle: FontStyle.italic,
        //   ),
        // ),
        // if (email.isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 2),
        //     child: Text(
        //       email,
        //       style: const TextStyle(
        //         color: Colors.white60,
        //         fontSize: 12,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFEB6B46)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFFEB6B46).withOpacity(0.1),
    );
  }
}