import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/Screen/chatscreen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserPicture;
  final String currentUserEmail;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPicture,
    required this.currentUserEmail,
  }) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chats = [];
  static const String baseUrl = 'http://182.93.94.210:3064';

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      log('Chat API Response: ${response.statusCode}');

      if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          setState(() {
            _chats = responseData['data'];
          });
        } else {
          throw Exception('Invalid chat list format');
        }
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching chats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching chats: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await AppData().logout();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('http://') || url.startsWith('https://')) return true;
    if (url.startsWith('/')) return true;
    return false;
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _chats.isEmpty
          ? const Center(child: Text('No chats available'))
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final user = chat['user'] as Map<String, dynamic>? ?? {'_id': '', 'name': 'Unknown', 'email': ''};

                final profilePicture = user['picture']?.toString() ?? '';
                final displayName = user['name']?.toString() ?? 'Unknown';
                final email = user['email']?.toString() ?? '';

                log('Profile picture URL: ${_getImageUrl(profilePicture)}');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: _isValidImageUrl(profilePicture)
                        ? ClipOval(
                            child: Image.network(
                              _getImageUrl(profilePicture),
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) => Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                        : Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20),
                          ),
                  ),
                  title: Text(displayName),
                  subtitle: Text(chat['lastMessage']?['message']?.toString() ?? 'No messages yet'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          currentUserId: widget.currentUserId,
                          currentUserName: widget.currentUserName,
                          currentUserPicture: widget.currentUserPicture,
                          currentUserEmail: widget.currentUserEmail,
                          receiverId: user['_id']?.toString() ?? '',
                          receiverName: displayName,
                          receiverPicture: profilePicture,
                          receiverEmail: email,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}