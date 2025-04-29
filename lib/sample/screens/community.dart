import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _postController = TextEditingController();
  XFile? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _posts = [];

  void _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _selectedMedia = pickedFile;
    });
  }

  void _postContent() {
    if (_postController.text.isNotEmpty || _selectedMedia != null) {
      setState(() {
        _posts.add({
          'profilePic': 'assets/images/profile_placeholder.png',
          'username': 'CurrentUser',
          'time': 'Just now',
          'content': _postController.text,
          'image': _selectedMedia?.path,
          'likes': 0,
          'comments': [],
        });
        _postController.clear();
        _selectedMedia = null;
      });
    }
  }

  void _likePost(int index) {
    setState(() {
      _posts[index]['likes']++;
    });
  }

  void _addComment(int index, String comment) {
    setState(() {
      _posts[index]['comments'].add(comment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPostSection(),
          // ignore: unnecessary_to_list_in_spreads
          ..._posts.map((post) => _buildPost(context, post)).toList(),
        ],
      ),
    );
  }

  Widget _buildPostSection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _postController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'What\'s on your mind?',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            if (_selectedMedia != null)
              Image.file(
                File(_selectedMedia!.path),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: () => _pickMedia(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: Icon(Icons.videocam),
                      onPressed: () =>
                          _pickMedia(ImageSource.gallery, isVideo: true),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _postContent,
                  child: Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPost(BuildContext context, Map<String, dynamic> post) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(post['profilePic']),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['username'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post['time'],
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // Post Content
            Text(post['content']),
            SizedBox(height: 10),

            // Post Image
            if (post['image'] != null)
              Image.file(
                File(post['image']),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

            // Post Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up_alt_outlined),
                      onPressed: () => _likePost(_posts.indexOf(post)),
                    ),
                    Text('${post['likes']}'),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.comment_outlined),
                  onPressed: () {
                    _showCommentDialog(context, _posts.indexOf(post));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
              ],
            ),

            // Comments Section
            if (post['comments'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post['comments']
                    .map<Widget>((comment) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Text(comment),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context, int postIndex) {
    // ignore: no_leading_underscores_for_local_identifiers
    final TextEditingController _commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a Comment'),
          content: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Comment',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  _addComment(postIndex, _commentController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Post'),
            ),
          ],
        );
      },
    );
  }
}
