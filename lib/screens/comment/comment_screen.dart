import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3065/api/v1/posts/${widget.postId}/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> commentsData = data['data'] ?? [];
        setState(() {
          _comments.clear();
          _comments.addAll(
            commentsData.map((comment) => Comment.fromJson(comment)).toList(),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3065/api/v1/posts/${widget.postId}/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': _commentController.text.trim()}),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        await _fetchComments(); // Refresh comments
      }
    } catch (e) {
      print('Error submitting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    } finally {
      setState(() => _isSendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return CommentTile(comment: comment);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: _isSendingComment
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSendingComment ? null : _submitComment,
                  color: const Color.fromRGBO(244, 135, 6, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            comment.authorPicture != null ? NetworkImage(comment.authorPicture!) : null,
        child: comment.authorPicture == null ? const Icon(Icons.person) : null,
      ),
      title: Row(
        children: [
          Text(
            comment.authorName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(comment.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(comment.content),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPicture;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPicture,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      content: json['content'],
      authorId: json['author']['_id'],
      authorName: json['author']['name'] ?? 'Unknown',
      authorPicture: json['author']['picture'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 