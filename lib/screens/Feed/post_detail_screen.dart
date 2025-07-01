import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/screens/Feed/Optimize%20Media/OptimizeMediaScreen.dart';
import 'package:innovator/screens/Feed/VideoPlayer/videoplayerpackage.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/screens/Likes/content-Like-Button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/screens/comment/comment_section.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class SpecificPostScreen extends StatefulWidget {
  final String contentId;
  final String? highlightAction;

  const SpecificPostScreen({
    Key? key,
    required this.contentId,
    this.highlightAction,
  }) : super(key: key);

  @override
  State<SpecificPostScreen> createState() => _SpecificPostScreenState();
}

class _SpecificPostScreenState extends State<SpecificPostScreen>
    with SingleTickerProviderStateMixin {
  SpecificPostContent? content;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool _showComments = false;
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3066',
  );

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _highlightAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.3),
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    ));
    
    fetchSpecificPost();
    
    // If there's a highlight action, show comments section and highlight
    if (widget.highlightAction != null) {
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showComments = true;
          });
          _highlightController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> fetchSpecificPost() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final String? authToken = AppData().authToken;
      if (authToken == null || authToken.isEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/content/${widget.contentId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 200 && data['data'] != null) {
          setState(() {
            content = SpecificPostContent.fromJson(data['data']);
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load post');
        }
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      } else if (response.statusCode == 404) {
        setState(() {
          hasError = true;
          errorMessage = 'Post not found';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading post: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (content != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _showShareOptions(context),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading post...'),
          ],
        ),
      );
    }

    if (hasError || content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              errorMessage.isNotEmpty ? errorMessage : 'Failed to load post',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchSpecificPost,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, child) {
              return Container(
                color: _highlightAnimation.value,
                child: _buildPostCard(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (content!.status.isNotEmpty) _buildStatusSection(),
          if (content!.hasMedia) _buildMediaSection(),
          _buildActionButtons(),
          _buildEngagementInfo(),
          if (_showComments) _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildAuthorAvatar(),
          const SizedBox(width: 16.0),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpecificUserProfilePage(
                      userId: content!.author.id,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          content!.author.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.0,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isAuthorCurrentUser()) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          width: 4.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        FollowButton(
                          targetUserEmail: content!.author.email,
                          initialFollowStatus: content!.engagement.following,
                          onFollowSuccess: () {
                            setState(() {
                              content!.engagement.following = true;
                            });
                          },
                          onUnfollowSuccess: () {
                            setState(() {
                              content!.engagement.following = false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(content!.type).withAlpha(50),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          content!.type,
                          style: TextStyle(
                            color: _getTypeColor(content!.type),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        _formatTimeAgo(content!.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar() {
    if (_isAuthorCurrentUser()) {
      return Obx(() {
        final userController = Get.find<UserController>();
        final picturePath = userController.getFullProfilePicturePath();
        final version = userController.profilePictureVersion.value;

        return CircleAvatar(
          radius: 24,
          backgroundImage: picturePath != null
              ? NetworkImage('$picturePath?v=$version')
              : null,
          child: picturePath == null || picturePath.isEmpty
              ? Text(content!.author.name.isNotEmpty
                  ? content!.author.name[0].toUpperCase()
                  : '?')
              : null,
        );
      });
    }

    return CachedNetworkImage(
      imageUrl: content!.author.picture,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 24,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => const CircleAvatar(
        radius: 24,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 24,
        child: Text(
          content!.author.name.isNotEmpty
              ? content!.author.name[0].toUpperCase()
              : '?',
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _LinkifyText(
        text: content!.status,
        style: const TextStyle(
          fontSize: 16.0,
          height: 1.5,
          color: Color(0xFF2D2D2D),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (!content!.hasMedia) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: _buildMediaPreview(),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (content!.optimizedFiles.isNotEmpty) {
      final optimizedFile = content!.optimizedFiles.first;
      
      if (optimizedFile.type == 'image') {
        return GestureDetector(
          onTap: () => _showMediaGallery([optimizedFile.url], 0),
          child: CachedNetworkImage(
            imageUrl: optimizedFile.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.error)),
            ),
          ),
        );
      } else if (optimizedFile.type == 'video') {
        return Container(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AutoPlayVideoWidget(
              url: optimizedFile.url,
              thumbnailUrl: optimizedFile.thumbnail,
            ),
          ),
        );
      }
    }

    // Fallback to original files
    if (content!.files.isNotEmpty) {
      final firstFile = content!.files.first;
      return GestureDetector(
        onTap: () => _showMediaGallery(content!.files, 0),
        child: CachedNetworkImage(
          imageUrl: firstFile,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LikeButton(
                  contentId: content!.id,
                  initialLikeStatus: content!.engagement.liked,
                  likeService: likeService,
                  onLikeToggled: (isLiked) {
                    setState(() {
                      content!.engagement.liked = isLiked;
                      content!.engagement.likes += isLiked ? 1 : -1;
                    });
                    SoundPlayer().playlikeSound();
                  },
                ),
                const SizedBox(width: 8.0),
                Text(
                  '${content!.engagement.likes}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            onTap: () {},
          ),
          _buildActionButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showComments ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: _showComments ? Colors.blue.shade600 : Colors.grey.shade600,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  '${content!.engagement.comments}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _showComments ? Colors.blue.shade600 : Colors.grey.shade700,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _showComments = !_showComments;
              });
            },
          ),
          _buildActionButton(
            child: Icon(
              Icons.share_outlined,
              color: Colors.grey.shade600,
              size: 20.0,
            ),
            onTap: () => _showShareOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEngagementInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '${content!.views} views',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.0,
            ),
          ),
          if (content!.engagement.engagementRate > 0) ...[
            const SizedBox(width: 16),
            Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${content!.engagement.engagementRate.toStringAsFixed(1)}% engagement',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: CommentSection(
        contentId: content!.id,
        onCommentAdded: () {
          setState(() {
            content!.engagement.comments++;
          });
        },
      ),
    );
  }

  Widget _buildMenuButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _showMenuOptions(context),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.more_horiz_rounded,
            color: Colors.grey.shade600,
            size: 20.0,
          ),
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('Copy content'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
              if (!_isAuthorCurrentUser()) ...[
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () => Navigator.pop(context, 'report'),
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block'),
                  onTap: () => Navigator.pop(context, 'block'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: content!.status));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content copied to clipboard')),
        );
      }
      // Add handlers for report and block if needed
    });
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Share Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share via Apps'),
                subtitle: const Text('Share using other apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaApps();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareViaApps() async {
    try {
      final shareText = 'Check out this post by ${content!.author.name}: ${content!.status}';
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing via apps: $e');
    }
  }

  void _showMediaGallery(List<String> mediaUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptimizedMediaGalleryScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  bool _isAuthorCurrentUser() {
    if (AppData().isCurrentUser(content!.author.id)) {
      return true;
    }

    final String? token = AppData().authToken;
    if (token != null && token.isNotEmpty) {
      try {
        final String? currentUserId = JwtHelper.extractUserId(token);
        if (currentUserId != null) {
          return currentUserId == content!.author.id;
        }
      } catch (e) {
        debugPrint('Error parsing JWT token: $e');
      }
    }
    return false;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'innovation':
        return Colors.blue.shade600;
      case 'post':
        return Colors.green.shade600;
      case 'photo':
        return Colors.purple.shade600;
      case 'video':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }
}

// Data Models
class SpecificPostContent {
  final String id;
  final String status;
  final List<String> files;
  final String type;
  final SpecificPostAuthor author;
  final DateTime createdAt;
  final int views;
  final bool isShared;
  final List<OptimizedFile> optimizedFiles;
  final String contentType;
  final SpecificPostEngagement engagement;
  final SpecificPostMetadata metadata;

  SpecificPostContent({
    required this.id,
    required this.status,
    required this.files,
    required this.type,
    required this.author,
    required this.createdAt,
    required this.views,
    required this.isShared,
    required this.optimizedFiles,
    required this.contentType,
    required this.engagement,
    required this.metadata,
  });

  bool get hasMedia => files.isNotEmpty || optimizedFiles.isNotEmpty;

  factory SpecificPostContent.fromJson(Map<String, dynamic> json) {
    return SpecificPostContent(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      files: List<String>.from(json['files'] ?? []),
      type: json['type'] ?? '',
      author: SpecificPostAuthor.fromJson(json['author'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      views: json['views'] ?? 0,
      isShared: json['isShared'] ?? false,
      optimizedFiles: (json['optimizedFiles'] as List<dynamic>? ?? [])
          .map((file) => OptimizedFile.fromJson(file))
          .toList(),
      contentType: json['contentType'] ?? '',
      engagement: SpecificPostEngagement.fromJson(json['engagement'] ?? {}),
      metadata: SpecificPostMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class SpecificPostAuthor {
  final String id;
  final String name;
  final String email;
  final String picture;

  SpecificPostAuthor({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
  });

  factory SpecificPostAuthor.fromJson(Map<String, dynamic> json) {
    return SpecificPostAuthor(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      picture: json['picture'] ?? '',
    );
  }
}

class OptimizedFile {
  final String url;
  final String type;
  final String? thumbnail;
  final bool compressed;

  OptimizedFile({
    required this.url,
    required this.type,
    this.thumbnail,
    required this.compressed,
  });

  factory OptimizedFile.fromJson(Map<String, dynamic> json) {
    return OptimizedFile(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      thumbnail: json['thumbnail'],
      compressed: json['compressed'] ?? false,
    );
  }
}

class SpecificPostEngagement {
  int likes;
  int comments;
  int shares;
  bool liked;
  bool commented;
  bool following;
  double engagementRate;

  SpecificPostEngagement({
    required this.likes,
    required this.comments,
    required this.shares,
    required this.liked,
    required this.commented,
    required this.following,
    required this.engagementRate,
  });

  factory SpecificPostEngagement.fromJson(Map<String, dynamic> json) {
    return SpecificPostEngagement(
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      liked: json['liked'] ?? false,
      commented: json['commented'] ?? false,
      following: json['following'] ?? false,
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
    );
  }
}

class SpecificPostMetadata {
  final bool canShare;
  final bool canDownload;
  final String loadPriority;
  final bool isPublic;
  final String processingStatus;

  SpecificPostMetadata({
    required this.canShare,
    required this.canDownload,
    required this.loadPriority,
    required this.isPublic,
    required this.processingStatus,
  });

  factory SpecificPostMetadata.fromJson(Map<String, dynamic> json) {
    return SpecificPostMetadata(
      canShare: json['canShare'] ?? true,
      canDownload: json['canDownload'] ?? false,
      loadPriority: json['loadPriority'] ?? 'normal',
      isPublic: json['isPublic'] ?? true,
      processingStatus: json['processingStatus'] ?? 'completed',
    );
  }
}

// Enhanced LinkifyText widget for handling URLs in post content
class _LinkifyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const _LinkifyText({
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final RegExp urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    final matches = urlRegExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: style?.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ) ??
              const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch $url')),
                );
              }
            },
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}