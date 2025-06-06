import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class SpecificFeedItem extends StatelessWidget {
  final SpecificFeedContent content;
  final ValueChanged<bool>? onLikeToggled;
  final ValueChanged<bool>? onFollowToggled;

  const SpecificFeedItem({
    Key? key,
    required this.content,
    this.onLikeToggled,
    this.onFollowToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onDoubleTap: () {
        if (!content.isLiked && onLikeToggled != null) {
          onLikeToggled!(true);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 0,
        color: isDarkMode ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildMedia(context),
            _buildInteractionBar(context),
            _buildCaption(context),
            _buildCommentPreview(context),
            _buildTimestamp(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: content.author.avatar.isNotEmpty
                ? CachedNetworkImageProvider(
                    'http://182.93.94.210:3064${content.author.avatar}')
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content.author.name.isNotEmpty
                  ? content.author.name
                  : content.author.email,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (onFollowToggled != null && !content.isAuthor)
            TextButton(
              onPressed: () => onFollowToggled!(!content.isFollowed),
              child: Text(
                content.isFollowed ? 'Following' : 'Follow',
                style: TextStyle(
                  color: content.isFollowed ? Colors.grey : Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // Show options (e.g., report, share, etc.)
              _showPostOptions(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final mediaUrl = content.medias.isNotEmpty
        ? 'http://182.93.94.210:3064${content.medias.first}'
        : null;
    return mediaUrl != null
        ? AspectRatio(
            aspectRatio: 1.0, // Instagram uses 1:1 for most posts
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildInteractionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              content.isLiked ? Icons.favorite : Icons.favorite_border,
              color: content.isLiked ? Colors.red : null,
              size: 24,
            ),
            onPressed: () => onLikeToggled?.call(!content.isLiked),
          ),
          Text('${content.likes}'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment_outlined, size: 24),
            onPressed: () {
              // Navigate to comments page
              Get.toNamed('/comments', arguments: content.id);
            },
          ),
          Text('${content.comments}'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 24),
            onPressed: () {
              // Share functionality
              _sharePost(context);
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bookmark_border, size: 24),
            onPressed: () {
              // Save post functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    if (content.status.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: content.author.name.isNotEmpty
                  ? content.author.name
                  : content.author.email,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: content.status),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: TextButton(
        onPressed: () {
          // Navigate to comments page
          Get.toNamed('/comments', arguments: content.id);
        },
        child: Text(
          'View all ${content.comments} comments',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Text(
        timeago.format(DateTime.parse(content.createdAt)),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              // Handle report
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              _sharePost(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy Link'),
            onTap: () {
              Navigator.pop(context);
              // Copy post link
            },
          ),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    // Implement share functionality (e.g., using share_plus package)
  }
}

class SpecificFeedContent {
  final String id;
  final Author author;
  final String status;
  final List<String> medias;
  final int likes;
  final int comments;
  final String createdAt;
  bool isLiked;
  bool isFollowed;
  final bool isAuthor;

  SpecificFeedContent({
    required this.id,
    required this.author,
    required this.status,
    required this.medias,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isLiked = false,
    this.isFollowed = false,
    this.isAuthor = false,
  });

  factory SpecificFeedContent.fromJson(Map<String, dynamic> json) {
    return SpecificFeedContent(
      id: json['_id'] ?? '',
      author: Author.fromJson(json['author'] ?? {}),
      status: json['status'] ?? '',
      medias: List<String>.from(json['medias'] ?? []),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      isLiked: json['isLiked'] ?? false,
      isFollowed: json['isFollowed'] ?? false,
      isAuthor: json['isAuthor'] ?? false,
    );
  }
}

class Author {
  final String id;
  final String name;
  final String email;
  final String avatar;

  Author({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}