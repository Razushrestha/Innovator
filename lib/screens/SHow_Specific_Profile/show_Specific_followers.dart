import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

// Import your existing AppData class
// import 'path_to_your_app_data.dart';

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
        Uri.parse('http://182.93.94.210:3064/api/v1/user-followers/${widget.userId}'),
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
        Uri.parse('http://182.93.94.210:3064/api/v1/user-following/${widget.userId}'),
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

  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowers != null) {
      return Center(child: Text(errorFollowers!));
    }
    
    if (followers.isEmpty) {
      return const Center(child: Text('No followers yet'));
    }
    
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        final isCurrentUser = appData.isCurrentUserByEmail(follower['email'] ?? '');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: follower['picture'] != null 
                ? NetworkImage('http://182.93.94.210:3064${follower['picture']}')
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(follower['name'] ?? 'User'),
          subtitle: Text(follower['email'] ?? ''),
          trailing: isCurrentUser 
              ? const Text('You', style: TextStyle(color: Colors.grey))
              : null,
        );
      },
    );
  }

  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowing != null) {
      return Center(child: Text(errorFollowing!));
    }
    
    if (following.isEmpty) {
      return const Center(child: Text('Not following anyone yet'));
    }
    
    return ListView.builder(
      itemCount: following.length,
      itemBuilder: (context, index) {
        final user = following[index];
        final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['picture'] != null 
                ? NetworkImage('http://182.93.94.210:3064${user['picture']}')
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(user['name'] ?? 'User'),
          subtitle: Text(user['email'] ?? ''),
          trailing: isCurrentUser 
              ? const Text('You', style: TextStyle(color: Colors.grey))
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(235, 111, 70, 1),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: 
      TabBarView(
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
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
        Uri.parse('http://182.93.94.210:3064/api/v1/user-followers/${widget.userId}'),
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
        Uri.parse('http://182.93.94.210:3064/api/v1/user-following/${widget.userId}'),
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

  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowers != null) {
      return Center(child: Text(errorFollowers!));
    }
    
    if (followers.isEmpty) {
      return const Center(child: Text('No followers yet'));
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final follower = followers[index];
        final isCurrentUser = appData.isCurrentUserByEmail(follower['email'] ?? '');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: follower['picture'] != null 
                ? NetworkImage('http://182.93.94.210:3064${follower['picture']}')
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(follower['name'] ?? 'User'),
          subtitle: Text(follower['email'] ?? ''),
          trailing: isCurrentUser 
              ? const Text('You', style: TextStyle(color: Colors.grey))
              : null,
        );
      },
    );
  }

  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorFollowing != null) {
      return Center(child: Text(errorFollowing!));
    }
    
    if (following.isEmpty) {
      return const Center(child: Text('Not following anyone yet'));
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: following.length,
      itemBuilder: (context, index) {
        final user = following[index];
        final isCurrentUser = appData.isCurrentUserByEmail(user['email'] ?? '');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['picture'] != null 
                ? NetworkImage('http://182.93.94.210:3064${user['picture']}')
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(user['name'] ?? 'User'),
          subtitle: Text(user['email'] ?? ''),
          trailing: isCurrentUser 
              ? const Text('ME', style: TextStyle(color: Colors.grey))
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(235, 111, 70, 1),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
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