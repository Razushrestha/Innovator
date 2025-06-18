import 'dart:async';
import 'dart:developer';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/main.dart';
import 'package:innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/screens/Likes/content-Like-Button.dart';
import 'package:innovator/screens/chatrrom/Screen/chat_listscreen.dart';
import 'package:innovator/screens/chatrrom/controller/chatlist_controller.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/screens/comment/comment_section.dart';
import 'package:innovator/widget/CustomizeFAB.dart';
import 'package:innovator/widget/Feed&Post.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:innovator/screens/Follow/follow_Button.dart'; // Add FollowButton import
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Add FollowService import

// Models (Author and FeedContent remain unchanged)
class Author {
  final String id;
  final String name;
  final String email;
  final String picture;

  const Author({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
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
  final String format;
  final List<String> qualities;
  final String thumbnail;
  final String original;
  final String hls;
  final String fileSize;

  OptimizedFile({
    required this.url,
    required this.type,
    required this.format,
    required this.qualities,
    required this.thumbnail,
    required this.original,
    required this.hls,
    required this.fileSize,
  });

  factory OptimizedFile.fromJson(Map<String, dynamic> json) {
    return OptimizedFile(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      format: json['format'] ?? '',
      qualities: List<String>.from(json['qualities'] ?? []),
      thumbnail: json['thumbnail'] ?? '',
      original: json['original'] ?? '',
      hls: json['hls'] ?? '',
      fileSize: json['fileSize'] ?? '',
    );
  }
}

class FeedContent {
  final String id;
  final String status;
  final String type;
  final List<String> files;
  final List<OptimizedFile> optimizedFiles;
  final Author author;
  final DateTime createdAt;
  final DateTime updatedAt;
  int likes;
  int comments;
  bool isLiked;
  bool isFollowed;

  late final List<String> _mediaUrls;
  late final bool _hasVideos;

  FeedContent({
    required this.id,
    required this.status,
    required this.type,
    required this.files,
    required this.optimizedFiles,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isFollowed = false,
  }) {
    // Prioritize original, then hls, then url
    _mediaUrls = optimizedFiles.isNotEmpty
        ? optimizedFiles.map((file) {
            if (file.original.isNotEmpty) return 'http://182.93.94.210:3065${file.original}';
            if (file.hls.isNotEmpty) return 'http://182.93.94.210:3065${file.hls}';
            if (file.url.isNotEmpty) return 'http://182.93.94.210:3065${file.url}';
            return '';
          }).where((url) => url.isNotEmpty).toList()
        : files.map((file) => 'http://182.93.94.210:3065$file').toList();

    _hasVideos = optimizedFiles.any((file) => file.type == 'video') ||
        files.any((file) =>
            file.toLowerCase().endsWith('.mp4') ||
            file.toLowerCase().endsWith('.mov') ||
            file.toLowerCase().endsWith('.avi') ||
            file.toLowerCase().endsWith('.m3u8'));
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    return FeedContent(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      files: List<String>.from(json['files'] ?? []),
      optimizedFiles: List<OptimizedFile>.from(
          (json['optimizedFiles'] ?? []).map((x) => OptimizedFile.fromJson(x))),
      author: Author.fromJson(json['author'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isLiked: json['liked'] ?? false,
      isFollowed: json['followed'] ?? false,
    );
  }

  bool get hasVideos => _hasVideos;
  List<String> get mediaUrls => _mediaUrls;

  // Get the best available thumbnail URL
  String? get thumbnailUrl {
    if (optimizedFiles.isNotEmpty && optimizedFiles.first.thumbnail.isNotEmpty) {
      return 'http://182.93.94.210:3065${optimizedFiles.first.thumbnail}';
    }
    return null;
  }
}

// Main Video Feed Page
class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({Key? key}) : super(key: key);

  @override
  _VideoFeedPageState createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<FeedContent> _videoContents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreVideos = true;
  String? _nextVideoCursor;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeAppData();
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
  }

  Future<void> _initializeAppData() async {
    await AppData().initialize();
    if (AppData().isAuthenticated) {
      await _loadVideoContent();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please log in to view videos';
      });
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } on SocketException catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _scrollListener() {
    if (!_isLoading &&
        _hasMoreVideos &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500.0) {
      _loadVideoContent();
    }
  }

  //  void _handleFeedToggle(bool isPost) {
  //   if (isPost) {
  //     // Navigate back to post feed or your main page
  //     Navigator.pop(context);
  //   }
  //   else{
  //     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => Homepage()), (route) => false);
  //   }
  //   // If !isPost, we're already on video feed, so no action needed
  // }

  Future<void> _loadVideoContent() async {
  if (_isLoading || !_hasMoreVideos) return;

  setState(() {
    _isLoading = true;
    _hasError = false;
  });

  try {
    if (!_isOnline) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No internet connection';
      });
      return;
    }

    final response = await _makeApiRequest();
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> videoList = data['data']['videoContents'] ?? [];
      final List<FeedContent> newVideos = [];

      for (var item in videoList) {
        final content = FeedContent.fromJson(item);
        final isFollowing = await FollowService.checkFollowStatus(
          content.author.email,
        );
        newVideos.add(FeedContent(
          id: content.id,
          status: content.status,
          type: content.type,
          files: content.files,
          optimizedFiles: content.optimizedFiles,
          author: content.author,
          createdAt: content.createdAt,
          updatedAt: content.updatedAt,
          likes: content.likes,
          comments: content.comments,
          isLiked: content.isLiked,
          isFollowed: isFollowing,
        ));
      }

      setState(() {
        _videoContents.addAll(newVideos);
        _hasMoreVideos = data['data']['hasMoreVideos'] ?? false;
        _nextVideoCursor = data['data']['nextVideoCursor'];
      });
    } else if (response.statusCode == 401) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Session expired. Please log in again.';
      });
      await AppData().logout();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load videos: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      _hasError = true;
      _errorMessage = 'No Internet Connection';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<http.Response> _makeApiRequest() async {
    final url = Uri.parse('http://182.93.94.210:3065/api/v1/list-contents?loadEngagement=true&quality=auto');
    
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${AppData().authToken}',
      },
    ).timeout(Duration(seconds: 30));
  }

   Future<void> _refresh() async {
    setState(() {
      _videoContents.clear();
      _nextVideoCursor = null;
      _hasError = false;
      _hasMoreVideos = true;
    });
    await _loadVideoContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        final content = _videoContents;

    return Scaffold(

      key: _scaffoldKey,
      body: Stack(
        children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (_hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          _isOnline
                              ? 'animation/No-Content.json'
                              : 'animation/No_Internet.json',
                          height: 200,
                        ),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: _errorMessage.contains('expired')
                                ? Colors.orange
                                : Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _hasError && _errorMessage.contains('log in')
                              ? () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage()), (route) => false)
                              : _refresh,
                          child: Text(
                            _hasError && _errorMessage.contains('log in')
                                ? 'Log In'
                                : 'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_videoContents.isEmpty && !_isLoading && !_hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('animation/No-Content.json', height: 200),
                        Text('No video content available'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _videoContents.length) {
                      return _isLoading
                          ? Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SizedBox.shrink();
                    }
                    return RepaintBoundary(
                            key: ValueKey(_videoContents),

                      child: VideoFeedItem(
                        
                        content: _videoContents[index],
                        onFollowToggled: (isFollowed) {
                          setState(() {
                            _videoContents[index].isFollowed = isFollowed;
                          });
                        },
                      
                              onLikeToggled: (isLiked) {
                                setState(() {
                                  _videoContents[index].isLiked = isLiked;
                                  _videoContents[index].likes += isLiked ? 1 : -1;
                                });
                              },
                      ),
                    );
                  },
                  childCount: _videoContents.length + (_hasMoreVideos ? 1 : 0),
                ),
              ),
            ],
          ),
        ),
       Positioned(
  top: mq.height * 0.01,
  right: mq.width * 0.03,
  child: FeedToggleButton(
    initialValue: false, // false for video feed (current page)
    accentColor: Color.fromRGBO(244, 135, 6, 1),
    onToggle: (bool isPost) {
      if (isPost) { // When switching to post feed
        Navigator.pop(context); // Go back to post feed
      }
      // If isPost is false, stay on current page (already on video feed)
    },
  ),
),
        ]
      ),
      floatingActionButton: GetBuilder<ChatListController>(
        init: () {
          if (!Get.isRegistered<ChatListController>()) {
            Get.put(ChatListController());
          }
          return Get.find<ChatListController>();
        }(),
        builder: (chatController) {
          return Obx(() {
            final unreadCount = chatController.totalUnreadCount;
            final isLoading = chatController.isLoading.value;
            final isMqttConnected = chatController.isMqttConnected.value;

            return CustomFAB(
              gifAsset: 'animation/chaticon.gif',
              onPressed: isLoading
                  ? () {}
                  : () async {
                      try {
                        print('FAB pressed! Current unread count: $unreadCount');
                        if (unreadCount > 0) {
                          chatController.resetAllUnreadCounts();
                        }
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatListScreen(
                              currentUserId: AppData().currentUserId ?? '',
                              currentUserName: AppData().currentUserName ?? '',
                              currentUserPicture: AppData().currentUserProfilePicture ?? '',
                              currentUserEmail: AppData().currentUserEmail ?? '',
                            ),
                          ),
                        );
                        print('Returned from ChatListScreen, refreshing data...');
                        if (Get.isRegistered<ChatListController>()) {
                          final controller = Get.find<ChatListController>();
                          if (!controller.isMqttConnected.value) {
                            await controller.initializeMQTT();
                          }
                          await controller.fetchChats();
                          print('Chat data refreshed. New unread count: ${controller.totalUnreadCount}');
                        }
                      } catch (e) {
                        print('Error in FAB onPressed: $e');
                        Get.snackbar(
                          'Error',
                          'Please Contact to Our Support Team',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              backgroundColor: Colors.transparent,
              elevation: 100.0,
              size: 56.0,
              showBadge: unreadCount > 0,
              badgeText: unreadCount > 99 ? '99+' : '$unreadCount',
              badgeColor: Colors.red,
              badgeTextColor: Colors.white,
              badgeSize: 24.0,
              badgeTextSize: 12.0,
              animationDuration: Duration(
                milliseconds: isMqttConnected ? 300 : 500,
              ),
            );
          });
        },
      ),
    );
  }
}

// Video Feed Item Widget
class VideoFeedItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool)? onFollowToggled;
  final Function(bool) onLikeToggled;


  const VideoFeedItem({
    Key? key,
    required this.content,
    this.onFollowToggled, required this.onLikeToggled,
  }) : super(key: key);

  @override
  _VideoFeedItemState createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> with SingleTickerProviderStateMixin {
  bool _showComments = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 3;

  late AnimationController _controller;
final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3065',
  );
  @override
  void initState() {
    super.initState();
    _isLiked = widget.content.isLiked;
    _likeCount = widget.content.likes;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
    

  bool _isAuthorCurrentUser() {
    return AppData().isCurrentUser(widget.content.author.id);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwnContent = _isAuthorCurrentUser();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${widget.content.author.id}_${_isAuthorCurrentUser() ? Get.find<UserController>().profilePictureVersion.value : 0}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(30),
                            blurRadius: 12.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: _buildAuthorAvatar(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.content.author.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.0,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isOwnContent) ...[
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: FollowButton(
                                  targetUserEmail: widget.content.author.email,
                                  initialFollowStatus: widget.content.isFollowed,
                                  onFollowSuccess: () {
                                    widget.onFollowToggled?.call(true);
                                  },
                                  onUnfollowSuccess: () {
                                    widget.onFollowToggled?.call(false);
                                  },
                                ),
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
                                color: _getTypeColor(widget.content.type).withAlpha(50),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                widget.content.type,
                                style: TextStyle(
                                  color: _getTypeColor(widget.content.type),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              widget.content.createdAt.timeAgo(),
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () => _showOptionsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.grey.shade600,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status Text
            if (widget.content.status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final span = TextSpan(
                          text: widget.content.status,
                          style: const TextStyle(fontSize: 15.0),
                        );
                        final tp = TextPainter(
                          text: span,
                          maxLines: _maxLinesCollapsed,
                          textDirection: TextDirection.ltr,
                        );
                        tp.layout(maxWidth: constraints.maxWidth);
                        final needsExpandCollapse = tp.didExceedMaxLines;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _LinkifyText(
                                text: widget.content.status,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  height: 1.5,
                                  color: Color(0xFF2D2D2D),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: _isExpanded ? null : _maxLinesCollapsed,
                                overflow: _isExpanded ? null : TextOverflow.ellipsis,
                              ),
                            ),
                            if (needsExpandCollapse)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: Text(
                                      _isExpanded ? 'Show Less' : 'Show More',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            // Video Content
            if (widget.content.hasVideos)
  Container(
    margin: const EdgeInsets.symmetric(horizontal: 5.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: LimitedBox(
        maxHeight: 300.0,
        child: AutoPlayVideoWidget(
          url: widget.content.mediaUrls.isNotEmpty
              ? widget.content.mediaUrls.first
              : '',
          fallbackUrls: widget.content.mediaUrls.length > 1
              ? widget.content.mediaUrls.sublist(1)
              : [],
          height: 350.0,
          thumbnailUrl: widget.content.thumbnailUrl,
        ),
      ),
    ),
  ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    _buildActionButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            LikeButton(
                              contentId: widget.content.id,
                              initialLikeStatus: widget.content.isLiked,
                              likeService: likeService,
                              onLikeToggled: (isLiked) {
                                widget.onLikeToggled(isLiked);
                                SoundPlayer player = SoundPlayer();
                                player.playlikeSound();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '${widget.content.likes}',
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _showComments
                                    ? Icons.chat_bubble
                                    : Icons.chat_bubble_outline,
                                color:
                                    _showComments
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade600,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '${widget.content.comments}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    _showComments
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade700,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
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
            ),
            // Comments Section
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child:
                  _showComments
                      ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: CommentSection(
                          contentId: widget.content.id,
                          onCommentAdded: () {
                            setState(() {
                              widget.content.comments++;
                            });
                          },
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
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

  Widget _buildAuthorAvatar() {
    if (widget.content.author.picture.isEmpty) {
      return CircleAvatar(
        child: Text(
          widget.content.author.name.isNotEmpty
              ? widget.content.author.name[0].toUpperCase()
              : '?',
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: 'http://182.93.94.210:3065${widget.content.author.picture}',
      imageBuilder: (context, imageProvider) => CircleAvatar(
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => const CircleAvatar(
        child: CircularProgressIndicator(strokeWidth: 2.0),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        child: Text(
          widget.content.author.name.isNotEmpty
              ? widget.content.author.name[0].toUpperCase()
              : '?',
        ),
      ),
    );
  }

  Future<void> _submitComment(String comment) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3065/api/v1/add-comment');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppData().authToken}',
        },
        body: jsonEncode({
          'contentId': widget.content.id,
          'userId': AppData().currentUserId,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          widget.content.comments += 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment added')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment')),
        );
      }
    } catch (e) {
      log('Error$e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e')),
      // );
    }
  }

  void _showOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
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
            leading: Icon(Icons.copy, color: Colors.blue),
            title: Text('Copy Link'),
            onTap: () {
              Navigator.pop(context);
              _copyLink();
            },
          ),
          ListTile(
            leading: Icon(Icons.flag, color: Colors.orange),
            title: Text('Report'),
            onTap: () {
              Navigator.pop(context);
              _reportContent();
            },
          ),
          if (_isAuthorCurrentUser())
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteContent();
              },
            ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _reportContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Content reported')),
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(
      text: 'http://182.93.94.210:3065/content/${widget.content.id}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _deleteContent() async {
    if (!AppData().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to delete content')),
      );
      return;
    }

    try {
      final url = Uri.parse('http://182.93.94.210:3065/api/v1/delete-content/${widget.content.id}');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppData().authToken}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Content deleted')),
        );
        context.findAncestorStateOfType<_VideoFeedPageState>()?._refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete content')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
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
            leading: Icon(Icons.link, color: Colors.blue),
            title: Text('Copy Link'),
            onTap: () {
              Navigator.pop(context);
              _copyLink();
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: Colors.green),
            title: Text('Share via Apps'),
            onTap: () {
              Navigator.pop(context);
              _shareViaSystem();
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _shareViaSystem() async {
    try {
      final videoUrl = widget.content.mediaUrls.firstWhere(
        (url) => url.toLowerCase().endsWith('.mp4') ||
            url.toLowerCase().endsWith('.mov') ||
            url.toLowerCase().endsWith('.avi'),
      );

      await Share.share(
        'Check out this video by ${widget.content.author.name}: $videoUrl',
        subject: 'Video shared from Video Feed',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share video')),
      );
    }
  }
}

// Auto Play Video Widget (unchanged)
class AutoPlayVideoWidget extends StatefulWidget {
  final String url; // Primary URL (original)
  final List<String> fallbackUrls; // Fallback URLs (hls, url)
  final double? height;
  final double? width;
  final String? thumbnailUrl;

  const AutoPlayVideoWidget({
    required this.url,
    required this.fallbackUrls,
    this.height,
    this.width,
    this.thumbnailUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<AutoPlayVideoWidget> createState() => AutoPlayVideoWidgetState();
}

class AutoPlayVideoWidgetState extends State<AutoPlayVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = true; // Start muted
  bool _disposed = false;
  Timer? _initTimer;
  bool _isPlaying = true;
  final String videoId = UniqueKey().toString();
  static final Map<String, AutoPlayVideoWidgetState> _activeVideos = {};
  int _currentUrlIndex = 0; // Track which URL is being tried

  @override
  bool get wantKeepAlive => _initialized;

  // Public methods to control the video
  void pauseVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void playVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void muteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.setVolume(0.0).then((_) {
        if (mounted) {
          setState(() {
            _isMuted = true;
          });
          developer.log('Video muted successfully for ID: $videoId',
              name: 'AutoPlayVideoWidget');
        }
      }).catchError((error) {
        developer.log('Error muting video for ID: $videoId: $error',
            name: 'AutoPlayVideoWidget');
      });
    }
  }

  void unmuteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.setVolume(1.0);
      setState(() {
        _isMuted = false;
      });
    }
  }

  void pauseAndMute() {
    pauseVideo();
    muteVideo();
  }

  void resumeWithPreviousState(bool wasMuted) {
    if (wasMuted) {
      muteVideo();
    } else {
      unmuteVideo();
    }
    playVideo();
  }

  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _initialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
    _activeVideos[videoId] = this;
  }

  void _initializeVideoPlayer() {
    if (_disposed) return;

    _initTimer = Timer(const Duration(seconds: 30), () {
      if (!_initialized && !_disposed) {
        _tryNextUrl();
      }
    });

    _initializeWithCurrentUrl();
  }

  void _initializeWithCurrentUrl() {
    if (_disposed) return;

    String currentUrl = _currentUrlIndex == 0
        ? widget.url
        : widget.fallbackUrls[_currentUrlIndex - 1];

    if (currentUrl.isEmpty) {
      _handleInitializationError();
      return;
    }

    // Check if URL is HLS (.m3u8)
    bool isHls = currentUrl.toLowerCase().endsWith('.m3u8');
    developer.log('Trying to initialize video with URL: $currentUrl (HLS: $isHls)',
        name: 'AutoPlayVideoWidget');

    _controller = isHls
        ? VideoPlayerController.networkUrl(
            Uri.parse(currentUrl),
            formatHint: VideoFormat.hls,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          )
        : VideoPlayerController.network(
            currentUrl,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          );

    _controller!
      ..setLooping(true)
      ..setVolume(0.0) // Start muted
      ..initialize().then((_) {
        _initTimer?.cancel();
        if (!_disposed && mounted) {
          setState(() {
            _initialized = true;
          });
          if (mounted) {
            _controller!.play();
          }
          developer.log('Video initialized successfully with URL: $currentUrl',
              name: 'AutoPlayVideoWidget');
        }
      }).catchError((error) {
        _initTimer?.cancel();
        developer.log('Error initializing video with URL: $currentUrl: $error',
            name: 'AutoPlayVideoWidget');
        if (!_disposed) {
          _tryNextUrl();
        }
      });
  }

  void _tryNextUrl() {
    if (_disposed) return;

    _currentUrlIndex++;
    if (_currentUrlIndex <= widget.fallbackUrls.length) {
      _controller?.dispose();
      _controller = null;
      _initializeWithCurrentUrl();
    } else {
      _handleInitializationError();
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _disposed || _controller == null) return;

    final visibleFraction = info.visibleFraction;

    if (visibleFraction > 0.5) {
      _activeVideos[videoId] = this;
      _muteOtherVideos();
      if (_initialized && !_controller!.value.isPlaying && _isPlaying) {
        _controller!.play();
      }
    } else {
      _activeVideos.remove(videoId);
      if (_initialized && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  void _muteOtherVideos() {
    for (final entry in _activeVideos.entries) {
      if (entry.key != videoId) {
        entry.value._controller?.pause();
        entry.value._isMuted = true;
        if (entry.value.mounted) {
          entry.value.setState(() {});
        }
      }
    }
  }

  static void pauseAllAutoPlayVideos() {
    for (final entry in _activeVideos.entries) {
      entry.value._controller?.pause();
      entry.value._controller?.setVolume(0.0);
      entry.value._isMuted = true;
      entry.value._isPlaying = false;
      if (entry.value.mounted) {
        entry.value.setState(() {});
      }
    }
  }

  static void resumeAllAutoPlayVideos() {
    for (final entry in _activeVideos.entries) {
      if (entry.value._initialized && entry.value.mounted) {
        entry.value._controller?.play();
        entry.value._isPlaying = true;
        entry.value._controller?.setVolume(0.0);
        entry.value._isMuted = true;
        entry.value.setState(() {});
      }
    }
  }

  void _handleInitializationError() {
    if (mounted && !_disposed) {
      setState(() {
        _initialized = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null || _disposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _controller!.pause();
        break;
      case AppLifecycleState.resumed:
        if (_initialized && mounted && _isPlaying) {
          _controller!.play();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller!.pause();
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _activeVideos.remove(videoId);
    _initTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || _disposed) return;

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || _disposed) return;

    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key(videoId),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Container(
        height: widget.height ?? MediaQuery.of(context).size.height,
        width: widget.width ?? MediaQuery.of(context).size.width,
        color: Colors.white,
        child: !_initialized || _controller == null
            ? Stack(
                children: [
                  if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) {
                        developer.log(
                          'Failed to load thumbnail: $url, Error: $error',
                          name: 'AutoPlayVideoWidget',
                        );
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 50,
                        ),
                      ),
                    ),
                  Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final size = _controller!.value.size;
                  final aspectRatio = size.width / size.height;

                  double targetWidth = constraints.maxWidth;
                  double targetHeight = constraints.maxWidth / aspectRatio;

                  if (targetHeight > constraints.maxHeight) {
                    targetHeight = constraints.maxHeight;
                    targetWidth = constraints.maxHeight * aspectRatio;
                  }

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: SizedBox(
                            width: targetWidth,
                            height: targetHeight,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        if (!_isPlaying)
                          Icon(
                            Icons.play_arrow,
                            size: 50,
                            color: Colors.white.withAlpha(80),
                          ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _toggleMute,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                 border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
// Linkify Text Widget
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
          ) ?? const TextStyle(
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

// Helper Extension for Time Formatting
extension DateTimeExtension on DateTime {
  String timeAgo() {
    final difference = DateTime.now().difference(this);
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
