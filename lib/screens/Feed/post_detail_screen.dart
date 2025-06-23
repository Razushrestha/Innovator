import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:innovator/screens/comment/comment_screen.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? highlightCommentId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.highlightCommentId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  Map<String, dynamic>? postData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3065/api/v1/posts/${widget.postId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          postData = data['data'];
          isLiked = postData?['isLiked'] ?? false;
          likeCount = postData?['likeCount'] ?? 0;
          commentCount = postData?['commentCount'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching post details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3065/api/v1/posts/${widget.postId}/like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: widget.postId),
      ),
    );
  }

  void _sharePost() {
    if (postData != null) {
      final content = postData!['content'] ?? '';
      final author = postData!['author']?['name'] ?? 'Unknown';
      Share.share('Check out this post by $author:\n\n$content');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (postData != null) ...[
                    // Author info
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: postData!['author']?['picture'] != null
                            ? NetworkImage(postData!['author']['picture'])
                            : null,
                        child: postData!['author']?['picture'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(postData!['author']?['name'] ?? 'Unknown'),
                      subtitle: Text(
                        DateTime.parse(postData!['createdAt']).toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Post content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        postData!['content'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    // Media content if any
                    if (postData!['media']?.isNotEmpty ?? false)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(postData!['media'][0]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    // Interaction buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInteractionButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          label: '$likeCount Likes',
                          color: isLiked ? Colors.red : null,
                          onTap: _toggleLike,
                        ),
                        _buildInteractionButton(
                          icon: Icons.comment,
                          label: '$commentCount Comments',
                          onTap: _navigateToComments,
                        ),
                        _buildInteractionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: _sharePost,
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
} 