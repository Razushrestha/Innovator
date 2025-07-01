import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/models/chat_model.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  
  const FollowersFollowingScreen({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _FollowersFollowingScreenState createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final appData = AppData();
  
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];
  
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  String? errorFollowers;
  String? errorFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowers();
    _fetchFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      isLoadingFollowers = true;
      errorFollowers = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/followers/${widget.userId}'),
        headers: {
          'authorization': 'Bearer ${appData.authToken}',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['status'] == 200) {
        setState(() {
          followers = List<Map<String, dynamic>>.from(data['data']);
          isLoadingFollowers = false;
        });
      } else {
        setState(() {
          errorFollowers = data['message'] ?? 'Failed to load followers';
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowers = 'Network error: $e';
        isLoadingFollowers = false;
      });
    }
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      isLoadingFollowing = true;
      errorFollowing = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/following/${widget.userId}'),
        headers: {
          'authorization': 'Bearer ${appData.authToken}',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['status'] == 200) {
        setState(() {
          following = List<Map<String, dynamic>>.from(data['data']);
          isLoadingFollowing = false;
        });
      } else {
        setState(() {
          errorFollowing = data['message'] ?? 'Failed to load following';
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowing = 'Network error: $e';
        isLoadingFollowing = false;
      });
    }
  }

  void _navigateToProfile(Map<String, dynamic> user) {
    final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
    
    // Don't navigate if it's the current user
    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your profile'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    // Debug: Print user data to understand the structure
    print('User data: $user');
    print('Available keys: ${user.keys.toList()}');
    
    // Try different possible ID fields based on your API response
    String? userId;
    
    // Check for common ID field names
    if (user['_id'] != null && user['_id'].toString().isNotEmpty) {
      userId = user['_id'].toString();
    } else if (user['id'] != null && user['id'].toString().isNotEmpty) {
      userId = user['id'].toString();
    } else if (user['userId'] != null && user['userId'].toString().isNotEmpty) {
      userId = user['userId'].toString();
    } else if (user['email'] != null && user['email'].toString().isNotEmpty) {
      userId = user['email'].toString();
    } else if (user['user_id'] != null && user['user_id'].toString().isNotEmpty) {
      userId = user['user_id'].toString();
    }
    
    print('Extracted userId: $userId');
    
    if (userId != null && userId.isNotEmpty) {
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecificUserProfilePage(userId: userId!), // Non-null assertion
          ),
        );
      } catch (error) {
        print('Navigation error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show error if no valid ID found
      print('No valid user ID found in user data: $user');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open profile: User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800]?.withOpacity(0.3) 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: isCurrentUser ? null : () => _navigateToProfile(user),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          backgroundImage: user['picture'] != null && user['picture'].toString().isNotEmpty
              ? NetworkImage('http://182.93.94.210:3066${user['picture']}')
              : null,
          child: user['picture'] == null || user['picture'].toString().isEmpty
              ? Text(
                  (user['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user['email'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: isCurrentUser 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You', 
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : const Icon(
                Icons.arrow_forward_ios, 
                size: 16, 
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (errorFollowers != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorFollowers!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchFollowers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (followers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No followers yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchFollowers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: followers.length,
        itemBuilder: (context, index) {
          return _buildUserTile(followers[index]);
        },
      ),
    );
  }

  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (errorFollowing != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorFollowing!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchFollowing,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (following.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Not following anyone yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: following.length,
        itemBuilder: (context, index) {
          return _buildUserTile(following[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0A0A0A) 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(235, 111, 70, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(235, 111, 70, 1),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('Followers (${followers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Following (${following.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersList(),
          _buildFollowingList(),
        ],
      ),
    );
  }
}

// Dialog function to show followers/following
void showFollowersFollowingDialog(BuildContext context, String userId) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1A1A1A) 
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: FollowersFollowingContent(userId: userId),
        ),
      );
    },
  );
}

// Separate widget for dialog content
class FollowersFollowingContent extends StatefulWidget {
  final String userId;
  
  const FollowersFollowingContent({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _FollowersFollowingContentState createState() => _FollowersFollowingContentState();
}

class _FollowersFollowingContentState extends State<FollowersFollowingContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final appData = AppData();
  
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];
  
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  String? errorFollowers;
  String? errorFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowers();
    _fetchFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      isLoadingFollowers = true;
      errorFollowers = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/followers/${widget.userId}'),
        headers: {
          'authorization': 'Bearer ${appData.authToken}',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['status'] == 200) {
        setState(() {
          followers = List<Map<String, dynamic>>.from(data['data']);
          isLoadingFollowers = false;
        });
      } else {
        setState(() {
          errorFollowers = data['message'] ?? 'Failed to load followers';
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowers = 'Network error: $e';
        isLoadingFollowers = false;
      });
    }
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      isLoadingFollowing = true;
      errorFollowing = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/following/${widget.userId}'),
        headers: {
          'authorization': 'Bearer ${appData.authToken}',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['status'] == 200) {
        setState(() {
          following = List<Map<String, dynamic>>.from(data['data']);
          isLoadingFollowing = false;
        });
      } else {
        setState(() {
          errorFollowing = data['message'] ?? 'Failed to load following';
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowing = 'Network error: $e';
        isLoadingFollowing = false;
      });
    }
  }

  void _navigateToProfile(Map<String, dynamic> user) {
    final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
    
    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your profile'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    // Close the dialog first
    Navigator.of(context).pop();
    
    // Debug: Print user data to understand the structure
    print('User data: $user');
    print('Available keys: ${user.keys.toList()}');
    
    // Try different possible ID fields based on your API response
    String? userId;
    
    // Check for common ID field names
    if (user['_id'] != null && user['_id'].toString().isNotEmpty) {
      userId = user['_id'].toString();
    } else if (user['id'] != null && user['id'].toString().isNotEmpty) {
      userId = user['id'].toString();
    } else if (user['userId'] != null && user['userId'].toString().isNotEmpty) {
      userId = user['userId'].toString();
    } else if (user['email'] != null && user['email'].toString().isNotEmpty) {
      userId = user['email'].toString();
    } else if (user['user_id'] != null && user['user_id'].toString().isNotEmpty) {
      userId = user['user_id'].toString();
    }
    
    print('Extracted userId: $userId');
    
    if (userId != null && userId.isNotEmpty) {
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecificUserProfilePage(userId: userId!), // Non-null assertion
          ),
        );
      } catch (error) {
        print('Navigation error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show error if no valid ID found
      print('No valid user ID found in user data: $user');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open profile: User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800]?.withOpacity(0.3) 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: isCurrentUser ? null : () => _navigateToProfile(user),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[300],
          backgroundImage: user['picture'] != null && user['picture'].toString().isNotEmpty
              ? NetworkImage('http://182.93.94.210:3066${user['picture']}')
              : null,
          child: user['picture'] == null || user['picture'].toString().isEmpty
              ? Text(
                  (user['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          user['email'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: isCurrentUser 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'You', 
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(
                Icons.arrow_forward_ios, 
                size: 14, 
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowers != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              errorFollowers!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    if (followers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No followers yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: followers.length,
      itemBuilder: (context, index) {
        return _buildUserTile(followers[index]);
      },
    );
  }

  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowing != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              errorFollowing!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    if (following.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Not following anyone yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: following.length,
      itemBuilder: (context, index) {
        return _buildUserTile(following[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Text(
                'Connections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(235, 111, 70, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(235, 111, 70, 1),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('Followers (${followers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('Following (${following.length})'),
                ],
              ),
            ),
          ],
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFollowersList(),
              _buildFollowingList(),
            ],
          ),
        ),
      ],
    );
  }
}