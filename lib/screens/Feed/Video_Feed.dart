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
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Models
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
    _mediaUrls = optimizedFiles.isNotEmpty
        ? optimizedFiles.map((file) {
            if (file.original.isNotEmpty) return 'http://182.93.94.210:3066${file.original}';
            if (file.hls.isNotEmpty) return 'http://182.93.94.210:3066${file.hls}';
            if (file.url.isNotEmpty) return 'http://182.93.94.210:3066${file.url}';
            return '';
          }).where((url) => url.isNotEmpty).toList()
        : files.map((file) => 'http://182.93.94.210:3066$file').toList();

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

  String? get thumbnailUrl {
    if (optimizedFiles.isNotEmpty && optimizedFiles.first.thumbnail.isNotEmpty) {
      return 'http://182.93.94.210:3066${optimizedFiles.first.thumbnail}';
    }
    return null;
  }
}

// Main Video Feed Page (Reels Style)
class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({Key? key}) : super(key: key);

  @override
  _VideoFeedPageState createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final List<FeedContent> _videoContents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreVideos = true;
  String? _nextVideoCursor;
  bool _isOnline = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initializeAppData();
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
    final url = Uri.parse('http://182.93.94.210:3066/api/v1/list-contents?loadEngagement=true&quality=auto');
    
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
  if (_isRefreshing) return;
  
  setState(() {
    _isRefreshing = true;
    _videoContents.clear();
    _nextVideoCursor = null;
    _hasError = false;
    _hasMoreVideos = true;
    _currentPage = 0;
  });
  
  try {
    await _loadVideoContent();
    // Reset page controller to first video
    if (_videoContents.isNotEmpty && _pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
}

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildReelsView() {
  return RefreshIndicator(
    key: _refreshIndicatorKey,
    onRefresh: _refresh,
    color: Colors.deepOrange,
    backgroundColor: Colors.white,
    strokeWidth: 3.0,
    displacement: 40.0,
    child: PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videoContents.length + (_hasMoreVideos ? 1 : 0),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        // Load more videos when we're near the end
        if (index >= _videoContents.length - 3 && _hasMoreVideos && !_isLoading) {
          _loadVideoContent();
        }
      },
      itemBuilder: (context, index) {
        if (index == _videoContents.length) {
          return _isLoading
              ? Center(child: CircularProgressIndicator())
              : SizedBox.shrink();
        }
        
        return ReelsVideoItem(
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
          isCurrent: index == _currentPage,
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          if (_hasError)
            Center(
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
            )
          else if (_videoContents.isEmpty && !_isLoading && !_isRefreshing)
            Center(
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
            )
          else if (_isRefreshing && _videoContents.isEmpty)
  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.deepOrange),
        SizedBox(height: 16),
        Text('Loading fresh content...', style: TextStyle(color: Colors.white)),
      ],
    ),
  )
          else
            _buildReelsView(),
          
          Positioned(
            top: mq.height * 0.01,
            right: mq.width * 0.03,
            child: FeedToggleButton(
              initialValue: false,
              accentColor: Color.fromRGBO(244, 135, 6, 1),
              onToggle: (bool isPost) {
                if (isPost) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
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
                        if (Get.isRegistered<ChatListController>()) {
                          final controller = Get.find<ChatListController>();
                          if (!controller.isMqttConnected.value) {
                            await controller.initializeMQTT();
                          }
                          await controller.fetchChats();
                        }
                      } catch (e) {
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

// Reels Video Item Widget
class ReelsVideoItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool)? onFollowToggled;
  final Function(bool) onLikeToggled;
  final bool isCurrent;

  const ReelsVideoItem({
    Key? key,
    required this.content,
    this.onFollowToggled,
    required this.onLikeToggled,
    required this.isCurrent,
  }) : super(key: key);

  @override
  _ReelsVideoItemState createState() => _ReelsVideoItemState();
}

class _ReelsVideoItemState extends State<ReelsVideoItem> {
  bool _showComments = false;
  bool _isLiked = false;
  bool _isFollowing = false;
  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3066',
  );

  @override
  void initState() {
    super.initState();
    _isLiked = widget.content.isLiked;
    _isFollowing = widget.content.isFollowed;
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

  Widget _buildSideActionBar() {
    return Positioned(
      right: 10,
      bottom: 80,
      child: Column(
        children: [
          // Like Button
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
              SizedBox(height: 8),
              Text(
                '${widget.content.likes}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Comment Button
          Column(
            children: [
              IconButton(
                icon: Icon(
                  _showComments ? Icons.chat : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _showComments = !_showComments;
                  });
                },
              ),
              Text(
                '${widget.content.comments}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Share Button
          IconButton(
            icon: Icon(Icons.share, color: Colors.white, size: 32),
            onPressed: () => _showShareOptions(context),
          ),
          SizedBox(height: 20),
          // More Options
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 32),
            onPressed: () => _showOptionsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
  return Positioned(
    left: 16,
    bottom: 80,
    right: 100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author Info
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.content.author.picture.isNotEmpty
                  ? CachedNetworkImageProvider(
                      'http://182.93.94.210:3066${widget.content.author.picture}')
                  : null,
              child: widget.content.author.picture.isEmpty
                  ? Text(widget.content.author.name.isNotEmpty
                      ? widget.content.author.name[0].toUpperCase()
                      : '?')
                  : null,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.content.author.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_isAuthorCurrentUser()) ...[
              SizedBox(width: 8),
              FollowButton(
                targetUserEmail: widget.content.author.email,
                initialFollowStatus: _isFollowing,
                onFollowSuccess: () {
                  setState(() {
                    _isFollowing = true;
                  });
                  widget.onFollowToggled?.call(true);
                },
                onUnfollowSuccess: () {
                  setState(() {
                    _isFollowing = false;
                  });
                  widget.onFollowToggled?.call(false);
                },
              ),
            ],
          ],
        ),
        SizedBox(height: 8),
        // Expandable Status Text
        if (widget.content.status.isNotEmpty)
          ExpandableStatusText(
            text: widget.content.status,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.3,
            ),
          ),
      ],
    ),
  );
}

 Widget _buildCommentsSection() {
  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showComments ? MediaQuery.of(context).size.height * 0.5 : 0, // Dynamic height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _showComments
          ? SingleChildScrollView(
              child: CommentSection(
                contentId: widget.content.id,
                onCommentAdded: () {
                  setState(() {
                    widget.content.comments++;
                  });
                },
              ),
            )
          : SizedBox.shrink(),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_showComments) {
          setState(() {
            _showComments = false;
          });
        } else {
          // Trigger play/pause only if comments section is not open
          final videoWidgetState = context.findAncestorStateOfType<AutoPlayVideoWidgetState>();
          videoWidgetState?._togglePlayPause();
        }
      },
      child: Stack(
        children: [
          // Video Player
          Container(
            color: Colors.black,
            child: Center( 
              child: widget.content.hasVideos
                  ? AutoPlayVideoWidget(
                      url: widget.content.mediaUrls.isNotEmpty
                          ? widget.content.mediaUrls.first
                          : '',
                      fallbackUrls: widget.content.mediaUrls.length > 1
                          ? widget.content.mediaUrls.sublist(1)
                          : [],
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      thumbnailUrl: widget.content.thumbnailUrl,
                      autoPlay: widget.isCurrent,
                    )
                  : Center(child: Text('No video available', style: TextStyle(color: Colors.white))),
            ),
          ),
          // Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // UI Elements
          _buildUserInfo(),
          _buildSideActionBar(),
          _buildCommentsSection(),
        ],
      ),
    );
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
      text: 'http://182.93.94.210:3066/content/${widget.content.id}',
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
      final url = Uri.parse('http://182.93.94.210:3066/api/v1/delete-content/${widget.content.id}');
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
        Navigator.pop(context);
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

// Auto Play Video Widget (Updated for Reels)
// Auto Play Video Widget (Fixed for proper autoplay on scroll)
class AutoPlayVideoWidget extends StatefulWidget {
  final String url;
  final List<String> fallbackUrls;
  final double? height;
  final double? width;
  final String? thumbnailUrl;
  final bool autoPlay;

  const AutoPlayVideoWidget({
    required this.url,
    required this.fallbackUrls,
    this.height,
    this.width,
    this.thumbnailUrl,
    this.autoPlay = true,
    Key? key,
  }) : super(key: key);

  @override
  State<AutoPlayVideoWidget> createState() => AutoPlayVideoWidgetState();
}

class AutoPlayVideoWidgetState extends State<AutoPlayVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = false;
  bool _disposed = false;
  Timer? _initTimer;
  bool _isPlaying = true;
  bool _wasPlayingBeforePause = true; // Track if video was playing before manual pause
  final String videoId = UniqueKey().toString();
  int _currentUrlIndex = 0;

  @override
  bool get wantKeepAlive => _initialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant AutoPlayVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle autoplay changes based on visibility
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay && _initialized && !_disposed) {
        // Video should start playing
        if (_wasPlayingBeforePause) {
          _resumeVideo();
        }
      } else if (!widget.autoPlay && _initialized && !_disposed) {
        // Video should pause
        _pauseVideo();
      }
    }
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

    bool isHls = currentUrl.toLowerCase().endsWith('.m3u8');
    _controller = isHls
        ? VideoPlayerController.networkUrl(
            Uri.parse(currentUrl),
            formatHint: VideoFormat.hls,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          )
        : VideoPlayerController.networkUrl(Uri.parse(
            currentUrl),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          );

    _controller!
      ..setLooping(true)
      ..setVolume(_isMuted ? 0.0 : 1.0)
      ..initialize().then((_) {
        _initTimer?.cancel();
        if (!_disposed && mounted) {
          setState(() {
            _initialized = true;
          });
          // Auto-play only if the widget is marked for autoplay
          if (mounted && widget.autoPlay && _wasPlayingBeforePause) {
            _controller!.play();
            _isPlaying = true;
          }
        }
      }).catchError((error) {
        _initTimer?.cancel();
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

  void _handleInitializationError() {
    if (mounted && !_disposed) {
      setState(() {
        _initialized = false;
      });
    }
  }

  void _pauseVideo() {
    if (_controller != null && _initialized && !_disposed) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resumeVideo() {
    if (_controller != null && _initialized && !_disposed) {
      _controller!.play();
      setState(() {
        _isPlaying = true;
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
        if (_initialized && mounted && _isPlaying && widget.autoPlay) {
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
      _wasPlayingBeforePause = _isPlaying; // Update the tracking variable
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

    return Container(
      height: widget.height ?? MediaQuery.of(context).size.height,
      width: widget.width ?? MediaQuery.of(context).size.width,
      color: Colors.black,
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
                      return Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade600,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade600,
                        size: 50,
                      ),
                    ),
                  ),
                Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
                if (!_isPlaying)
                  Icon(
                    Icons.play_arrow,
                    size: 50,
                    color: Colors.white.withOpacity(0.7),
                  ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleMute,
                  ),
                ),
              ],
            ),
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


class ExpandableStatusText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;

  const ExpandableStatusText({
    Key? key,
    required this.text,
    this.maxLines = 2,
    this.style,
  }) : super(key: key);

  @override
  _ExpandableStatusTextState createState() => _ExpandableStatusTextState();
}

class _ExpandableStatusTextState extends State<ExpandableStatusText> {
  bool _isExpanded = false;
  bool _isTextOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style ?? TextStyle(color: Colors.white),
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 120); // Account for padding and side buttons

    if (textPainter.didExceedMaxLines) {
      setState(() {
        _isTextOverflowing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style ?? TextStyle(color: Colors.white),
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (_isTextOverflowing)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _isExpanded ? 'Show Less' : 'Show More',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}