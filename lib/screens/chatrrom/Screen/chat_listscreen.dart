import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/chatrrom/Screen/chatscreen.dart';
import 'package:innovator/screens/chatrrom/utils.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

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

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> _chats = [];
  List<dynamic> _filteredChats = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChats();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = _chats.where((chat) {
        final user = chat['user'] as Map<String, dynamic>? ?? {};
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchChats() async {
    try {
      final token = AppData().authToken;
      if (token == null) {
        throw Exception('No auth token available');
      }

      final response = await http.get(
        Uri.parse('${Utils.baseUrl}/api/v1/chats'),
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
            _filteredChats = _chats; // Initialize filtered list
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

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(244, 135, 6, 0.2),
                  Color.fromRGBO(244, 135, 6, 0.1),
                  Colors.grey,
                ],
              ),
            ),
            child: Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(244, 135, 6, 1)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                // Chat List
                Expanded(
                  child: _filteredChats.isEmpty
                      ? const Center(child: Text('No chats available'))
                      : ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final user = chat['user'] as Map<String, dynamic>? ?? {'_id': '', 'name': 'Unknown', 'email': ''};
                            final profilePicture = user['picture']?.toString() ?? '';
                            final displayName = user['name']?.toString() ?? 'Unknown';
                            final email = user['email']?.toString() ?? '';

                            log('Profile picture URL: ${Utils.getImageUrl(profilePicture)}');

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                radius: 24,
                                child: Utils.isValidImageUrl(profilePicture)
                                    ? ClipOval(
                                        child: Image.network(
                                          Utils.getImageUrl(profilePicture),
                                          fit: BoxFit.cover,
                                          width: 48,
                                          height: 48,
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
                              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              ],
            ),
          ),
          FloatingMenuWidget(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }
}