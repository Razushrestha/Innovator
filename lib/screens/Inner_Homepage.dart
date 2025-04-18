import 'package:flutter/material.dart';
import 'package:innovator/models/chat_user.dart';
import 'package:innovator/profile_page.dart';
import 'package:innovator/screens/Create_post.dart';
import 'package:innovator/screens/post_card.dart';

class Inner_HomePage extends StatefulWidget {
  final ChatUser user;
  const Inner_HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _Inner_HomePageState createState() => _Inner_HomePageState();
}

class _Inner_HomePageState extends State<Inner_HomePage> {
  final List<Post> _posts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadMorePosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate new posts
    final newPosts = List.generate(
      10,
      (index) => Post(
        id: '${_currentPage * 10 + index}',
        name: 'User ${_currentPage * 10 + index}',
        position: 'Position ${_currentPage * 10 + index}',
        description: 'This is a description for post ${_currentPage * 10 + index}. '
            'It contains details about the post and what the user wants to share.',
        imageUrl: 'https://picsum.photos/500/300?random=${_currentPage * 10 + index}',
        likes: (_currentPage * 10 + index) * 5,
        comments: (_currentPage * 10 + index) * 2,
        shares: (_currentPage * 10 + index),
      ),
    );

    setState(() {
      _posts.addAll(newPosts);
      _currentPage++;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('CircleNutary'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.search),
      //       onPressed: () {},
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.notifications),
      //       onPressed: () {},
      //     ),
      //   ],
      // ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _posts.clear();
            _currentPage = 0;
          });
          _loadMorePosts();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + 1,
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            
            final post = _posts[index];
            return PostCard(post: post);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}

// lib/models/post.dart
class Post {
  final String id;
  final String name;
  final String position;
  final String description;
  final String imageUrl;
  final int likes;
  final int comments;
  final int shares;
  bool isLiked = false;

  Post({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}


