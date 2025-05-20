import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

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

  Future<void> _fetchSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/list-contents?name='),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['contents'];
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading suggestions: $e')));
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
        Uri.parse('http://182.93.94.210:3064/api/v1/list-contents?name=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['contents'];
        setState(() {
          _searchResults = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
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
                child:
                    _isLoading
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
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            if (_isSearching)
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final user = _searchResults[index]['author'];
                                  return _buildUserTile(user, context);
                                }, childCount: _searchResults.length),
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
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_isSearching)
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final user = _suggestedUsers[index]['author'];
                                  return _buildUserTile(user, context);
                                }, childCount: _suggestedUsers.length),
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
                                        color:
                                            isDarkMode
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
          FloatingMenuWidget(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            CircleAvatar(
              radius: 30,
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              backgroundImage:
                  user['picture'] != null && user['picture'].isNotEmpty
                      ? CachedNetworkImageProvider(
                        'http://182.93.94.210:3064${user['picture']}',
                      )
                      : null,
              child:
                  user['picture'] == null || user['picture'].isEmpty
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
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Follow ${user['name']}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
