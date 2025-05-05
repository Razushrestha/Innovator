import 'package:flutter/material.dart';
import 'package:innovator/screens/Feed/Post.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFFAFAFA),
      margin: EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important to prevent overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            title: Text(post.name),
            subtitle: Text(post.position),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(post.description),
            
          ),
          if (post.imageUrl.isNotEmpty)
            Image.network(
              post.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          OverflowBar(
            children: [
              // IconButton(
              //   icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border),
              //   color: post.isLiked ? Colors.red : null,
              //   onPressed: () {},
              // ),
              // IconButton(
              //   icon: Icon(Icons.comment),
              //   onPressed: () {
              //     CommentSection(
              //       contentId,
              //     );
              //   },
              // ),
              // IconButton(
              //   icon: Icon(Icons.share),
              //   onPressed: () {
                  
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }
}