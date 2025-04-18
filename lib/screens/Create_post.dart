import 'package:flutter/material.dart';
import 'package:innovator/screens/OptionButton.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _hasImage = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: () {
              // Save post logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post created successfully!')),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'POST',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                const CircleAvatar(
                  radius: 24.0,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user'),
                ),
                const SizedBox(width: 12.0),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      'Senior Developer',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Text field for post content
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
            
            // Selected image preview (if any)
            if (_hasImage)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                  image: const DecorationImage(
                    image: NetworkImage('https://picsum.photos/500/300?random=new_post'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () {
                        setState(() {
                          _hasImage = false;
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasImage = true;
                  });
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 64,
                        color: Colors.grey,
                      ),
                      Text(
                        'Add Photo/Video',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16.0),
            
            // Additional options
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OptionButton(icon: Icons.photo_library, label: 'Gallery'),
                OptionButton(icon: Icons.tag, label: 'Tag People'),
                OptionButton(icon: Icons.location_on, label: 'Check In'),
                OptionButton(icon: Icons.emoji_emotions, label: 'Feeling'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}