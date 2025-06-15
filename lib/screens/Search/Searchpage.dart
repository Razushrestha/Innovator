import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

import '../../controllers/user_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final AppData _appData = AppData();
  List<dynamic> _searchResults = [];
  List<dynamic> _suggestedUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedUsers();
  }

  List<dynamic> _filterUniqueUsers(List<dynamic> users) {
    final uniqueEmails = <String>{};
    return users.where((user) {
      final email = user['email'] ?? '';
      if (email.isEmpty || uniqueEmails.contains(email)) {
        return false;
      }
      uniqueEmails.add(email);
      return true;
    }).toList();
  }

  Future<void> _fetchSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        setState(() {
          _suggestedUsers = data.take(5).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')));
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        setState(() {
          _searchResults = data
              .where((user) =>
                  user['name']
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false)
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 50),
              // Search box in body
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search people...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) {
                      _searchUsers(value);
                    },
                  ),
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [
                          if (_isSearching && _searchResults.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Search Results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          if (_isSearching)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final user = _searchResults[index];
                                  return _buildUserTile(user, context);
                                },
                                childCount: _searchResults.length,
                              ),
                            ),
                          if (!_isSearching)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Suggested People',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          if (!_isSearching)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final user = _suggestedUsers[index];
                                  return _buildUserTile(user, context);
                                },
                                childCount: _suggestedUsers.length,
                              ),
                            ),
                          if (_isSearching && _searchResults.isEmpty)
                            SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'No results found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
          FloatingMenuWidget(),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
final userController = Get.find<UserController>(); // Access UserController
  final isCurrentUser = user['_id'] == AppData().currentUserId;
    return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpecificUserProfilePage(userId: user['_id']),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          isCurrentUser
              ? Obx(
                  () => CircleAvatar(
                    radius: 30,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    key: ValueKey('search_avatar_${user['_id']}_${userController.profilePictureVersion.value}'),
                    backgroundImage: userController.profilePicture.value != null &&
                            userController.profilePicture.value!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            '${userController.getFullProfilePicturePath()}?v=${userController.profilePictureVersion.value}',
                          )
                        : null,
                    child: userController.profilePicture.value == null ||
                            userController.profilePicture.value!.isEmpty
                        ? Text(
                            user['name']?[0] ?? '?',
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                )
              : CircleAvatar(
                  radius: 30,
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  backgroundImage: user['picture'] != null && user['picture'].isNotEmpty
                      ? CachedNetworkImageProvider(
                          'http://182.93.94.210:3064${user['picture']}?t=${DateTime.now().millisecondsSinceEpoch}',
                        )
                      : null,
                  child: user['picture'] == null || user['picture'].isEmpty
                      ? Text(
                          user['name']?[0] ?? '?',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<bool>(
            future: FollowService.checkFollowStatus(user['email'] ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final isFollowing = snapshot.data ?? false;
              return FollowButton(
                targetUserEmail: user['email'] ?? '',
                initialFollowStatus: isFollowing,
                onFollowSuccess: () {
                  setState(() {});
                },
                onUnfollowSuccess: () {
                  setState(() {});
                },
                size: 36,
              );
            },
          ),
        ],
      ),
    ),
  );
  }
} 