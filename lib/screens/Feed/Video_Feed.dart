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

// Updated Models for new API structure
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

// Updated StreamingUrls class to match new API
class StreamingUrls {
  final String hls;
  final String original;
  final String thumbnail;

  StreamingUrls({
    required this.hls,
    required this.original,
    required this.thumbnail,
  });

  factory StreamingUrls.fromJson(Map<String, dynamic> json) {
    return StreamingUrls(
      hls: json['hls'] ?? '',
      original: json['original'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}

// Updated PlaybackSettings class
class PlaybackSettings {
  final bool autoplay;
  final bool muted;
  final bool loop;
  final String preload;
  final bool controls;
  final bool playsInline;

  PlaybackSettings({
    required this.autoplay,
    required this.muted,
    required this.loop,
    required this.preload,
    required this.controls,
    required this.playsInline,
  });

  factory PlaybackSettings.fromJson(Map<String, dynamic> json) {
    return PlaybackSettings(
      autoplay: json['autoplay'] ?? true,
      muted: json['muted'] ?? true,
      loop: json['loop'] ?? true,
      preload: json['preload'] ?? 'auto',
      controls: json['controls'] ?? true,
      playsInline: json['playsInline'] ?? true,
    );
  }
}

// Updated FeedContent class for new API structure
class FeedContent {
  final String id;
  final String status;
  final String type;
  final Author author;
  final DateTime createdAt;
  final int views;
  final bool isShared;
  final String videoUrl;
  final List<String> allFiles;
  final StreamingUrls streamingUrls;
  final PlaybackSettings playbackSettings;
  final double engagementRate;
  final bool canShare;
  final bool canDownload;
  final String contentType;
  final String feedPosition;
  final String loadPriority;
  final bool hasMore;
  
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isCommented;
  bool isFollowing;

  final List<String> _mediaUrls;
  final bool _hasVideos;

  FeedContent({
    required this.id,
    required this.status,
    required this.type,
    required this.author,
    required this.createdAt,
    required this.views,
    required this.isShared,
    required this.videoUrl,
    required this.allFiles,
    required this.streamingUrls,
    required this.playbackSettings,
    required this.engagementRate,
    required this.canShare,
    required this.canDownload,
    required this.contentType,
    required this.feedPosition,
    required this.loadPriority,
    required this.hasMore,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isCommented = false,
    this.isFollowing = false,
  }) : _mediaUrls = _buildMediaUrls(streamingUrls, videoUrl, allFiles),
       _hasVideos = _checkHasVideos(contentType, videoUrl, allFiles);

  // Static method to build media URLs
  static List<String> _buildMediaUrls(StreamingUrls streamingUrls, String videoUrl, List<String> allFiles) {
    final List<String> mediaUrls = [];
    
    // Add HLS URL if available
    if (streamingUrls.hls.isNotEmpty) {
      mediaUrls.add('http://182.93.94.210:3066${streamingUrls.hls}');
    }
    
    // Add original video URL if available
    if (streamingUrls.original.isNotEmpty) {
      mediaUrls.add('http://182.93.94.210:3066${streamingUrls.original}');
    }
    
    // Add main video URL if available
    if (videoUrl.isNotEmpty) {
      mediaUrls.add('http://182.93.94.210:3066$videoUrl');
    }
    
    // Add other files
    mediaUrls.addAll(allFiles.map((file) => 'http://182.93.94.210:3066$file'));
    
    // Remove duplicates
    return mediaUrls.toSet().toList();
  }

  // Static method to check if content has videos
  static bool _checkHasVideos(String contentType, String videoUrl, List<String> allFiles) {
    return contentType == 'video' || 
           videoUrl.isNotEmpty || 
           allFiles.any((file) =>
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
      author: Author.fromJson(json['author'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      views: json['views'] ?? 0,
      isShared: json['isShared'] ?? false,
      videoUrl: json['videoUrl'] ?? '',
      allFiles: List<String>.from(json['allFiles'] ?? []),
      streamingUrls: StreamingUrls.fromJson(json['streamingUrls'] ?? {}),
      playbackSettings: PlaybackSettings.fromJson(json['playbackSettings'] ?? {}),
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
      canShare: json['canShare'] ?? true,
      canDownload: json['canDownload'] ?? false,
      contentType: json['contentType'] ?? '',
      feedPosition: json['feedPosition'] ?? 'normal',
      loadPriority: json['loadPriority'] ?? 'normal',
      hasMore: json['hasMore'] ?? false,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      isLiked: json['liked'] ?? false,
      isCommented: json['commented'] ?? false,
      isFollowing: json['following'] ?? json['isFollowing'] ?? false,
    );
  }

  bool get hasVideos => _hasVideos;
  List<String> get mediaUrls => _mediaUrls;

  String? get thumbnailUrl {
    if (streamingUrls.thumbnail.isNotEmpty) {
      return 'http://182.93.94.210:3066${streamingUrls.thumbnail}';
    }
    return null;
  }
}

// API Response wrapper for new structure
class VideoApiResponse {
  final int status;
  final FeedContent? data;
  final String? error;
  final String message;

  VideoApiResponse({
    required this.status,
    this.data,
    this.error,
    required this.message,
  });

  factory VideoApiResponse.fromJson(Map<String, dynamic> json) {
    return VideoApiResponse(
      status: json['status'] ?? 0,
      data: json['data'] != null ? FeedContent.fromJson(json['data']) : null,
      error: json['error'],
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status == 200 && data != null;
}

// Main Video Feed Page (Updated for new API)
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
  
  // Track loaded video IDs to avoid duplicates
  final Set<String> _loadedVideoIds = {};

  @override
  void initState() {
    super.initState();
    _initializeAppData();
    _checkConnectivity();
  }

  Future<void> _initializeAppData() async {
    try {
      await AppData().initialize();
      
      if (AppData().isAuthenticated) {
        await _loadVideoContent();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please log in to view videos';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Initialization error: ${e.toString()}';
      });
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      // First try a simple HTTP request to your API server
      final testResponse = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      setState(() {
        _isOnline = testResponse.statusCode == 200 || testResponse.statusCode == 404; // 404 is OK if health endpoint doesn't exist
      });
    } catch (e) {
      // Fallback to Google DNS check
      try {
        final result = await InternetAddress.lookup('8.8.8.8');
        setState(() {
          _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        });
      } on SocketException catch (e) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  Future<void> _loadVideoContent() async {
    if (_isLoading || !_hasMoreVideos) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Make API request to get single video reel
      final response = await _makeApiRequest();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final apiResponse = VideoApiResponse.fromJson(responseData);
        
        if (apiResponse.isSuccess && apiResponse.data != null) {
          final content = apiResponse.data!;
          
          // Check if we already have this video to avoid duplicates
          if (!_loadedVideoIds.contains(content.id) && content.hasVideos) {
            final isFollowing = await FollowService.checkFollowStatus(
              content.author.email,
            );
            
            // Update the existing content with follow status instead of creating a new one
            content.isFollowing = isFollowing;

            setState(() {
              _videoContents.add(content);
              _loadedVideoIds.add(content.id);
              _hasMoreVideos = content.hasMore;
              _isOnline = true; // We successfully got data, so we're online
            });
          } else {
            // If duplicate or no videos, try to load next one
            if (_hasMoreVideos && content.hasMore) {
              // Add small delay to prevent rapid successive calls
              await Future.delayed(Duration(milliseconds: 500));
              _loadVideoContent();
            } else {
              // No more videos available
              setState(() {
                _hasMoreVideos = false;
              });
            }
          }
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = apiResponse.error ?? 'Failed to load video content';
          });
        }
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
      } else if (response.statusCode == 404) {
        // No more content available
        setState(() {
          _hasMoreVideos = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load videos: ${response.statusCode}';
          _isOnline = false; // Mark as offline if we get HTTP errors
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Connection Error: ${e.toString()}';
        _isOnline = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<http.Response> _makeApiRequest() async {
    // Updated to use the new video-reel endpoint
    final url = Uri.parse('http://182.93.94.210:3066/api/v1/video-reel');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppData().authToken}',
        },
      ).timeout(Duration(seconds: 30));
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _videoContents.clear();
      _loadedVideoIds.clear();
      _nextVideoCursor = null;
      _hasError = false;
      _hasMoreVideos = true;
      _currentPage = 0;
    });
    
    try {
      await _loadVideoContent();
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
        // Prevent scrolling when no more videos and not loading
        physics: (!_hasMoreVideos && !_isLoading && _videoContents.isNotEmpty) 
            ? NeverScrollableScrollPhysics() 
            : AlwaysScrollableScrollPhysics(),
        itemCount: _videoContents.length + (_hasMoreVideos ? 1 : 0),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          // Load more videos when approaching the end
          if (index >= _videoContents.length - 2 && _hasMoreVideos && !_isLoading) {
            _loadVideoContent();
          }
        },
        itemBuilder: (context, index) {
          if (index == _videoContents.length) {
            // Show loading or "no more videos" message
            if (_isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text(
                      'Loading more videos...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else if (!_hasMoreVideos) {
              // No more videos available - this should not be reached due to physics but keep as fallback
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'animation/No-Content.json', 
                        height: 150,
                        repeat: false,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'You\'ve reached the end!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pull down to refresh for new content',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _refresh,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Refresh for more',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }
          
          return ReelsVideoItem(
            content: _videoContents[index],
            onFollowToggled: (isFollowed) {
              setState(() {
                _videoContents[index].isFollowing = isFollowed;
              });
            },
            onLikeToggled: (isLiked) {
              setState(() {
                _videoContents[index].isLiked = isLiked;
                _videoContents[index].likes += isLiked ? 1 : -1;
              });
            },
            isCurrent: index == _currentPage,
            isLastVideo: !_hasMoreVideos && index == _videoContents.length - 1,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: _errorMessage.contains('expired')
                            ? Colors.orange
                            : Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                        ? () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                            (route) => false)
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
                  Text(
                    'No video content available',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _refresh,
                    child: Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white),
                    ),
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
                  Text(
                    'Loading fresh content...',
                    style: TextStyle(color: Colors.white),
                  ),
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

// Updated Reels Video Item Widget
class ReelsVideoItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool)? onFollowToggled;
  final Function(bool) onLikeToggled;
  final bool isCurrent;
  final bool isLastVideo;

  const ReelsVideoItem({
    Key? key,
    required this.content,
    this.onFollowToggled,
    required this.onLikeToggled,
    required this.isCurrent,
    this.isLastVideo = false,
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
    _isFollowing = widget.content.isFollowing;
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
          // Share Button (only show if canShare is true)
          if (widget.content.canShare)
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white, size: 32),
                  onPressed: () => _showShareOptions(context),
                ),
                Text(
                  '${widget.content.shares}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                    ? CachedNetworkImageProvider(widget.content.author.picture)
                    : null,
                child: widget.content.author.picture.isEmpty
                    ? Text(widget.content.author.name.isNotEmpty
                        ? widget.content.author.name[0].toUpperCase()
                        : '?')
                    : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content.author.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show views count and engagement rate
                    Text(
                      '${widget.content.views} views • ${widget.content.engagementRate.toStringAsFixed(1)}% engagement',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
          // Feed Position and Load Priority Info (Debug info, remove in production)
          if (widget.content.feedPosition != 'normal' || widget.content.loadPriority != 'normal')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.content.feedPosition} • ${widget.content.loadPriority}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
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
        height: _showComments ? MediaQuery.of(context).size.height * 0.5 : 0,
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
                      playbackSettings: widget.content.playbackSettings,
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
          
          // Show "End of Videos" overlay on last video when no more videos
          if (widget.isLastVideo)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepOrange, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.deepOrange,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'You\'ve reached the end!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pull down to refresh for new content',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          if (widget.content.canDownload)
            ListTile(
              leading: Icon(Icons.download, color: Colors.green),
              title: Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadContent();
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
      text: 'http://182.93.94.210:3066/api/v1/video-reel/${widget.content.id}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _downloadContent() {
    if (widget.content.canDownload) {
      // Implement download functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download started...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download not allowed for this content')),
      );
    }
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
    if (!widget.content.canShare) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sharing is not allowed for this content')),
      );
      return;
    }

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
        orElse: () => widget.content.mediaUrls.isNotEmpty ? widget.content.mediaUrls.first : '',
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

// Updated Auto Play Video Widget (Enhanced for new API with playback settings)
class AutoPlayVideoWidget extends StatefulWidget {
  final String url;
  final List<String> fallbackUrls;
  final double? height;
  final double? width;
  final String? thumbnailUrl;
  final bool autoPlay;
  final PlaybackSettings? playbackSettings;

  const AutoPlayVideoWidget({
    required this.url,
    required this.fallbackUrls,
    this.height,
    this.width,
    this.thumbnailUrl,
    this.autoPlay = true,
    this.playbackSettings,
    Key? key,
  }) : super(key: key);

  @override
  State<AutoPlayVideoWidget> createState() => AutoPlayVideoWidgetState();
}

class AutoPlayVideoWidgetState extends State<AutoPlayVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = false;
  bool _disposed = false;
  Timer? _initTimer;
  bool _isPlaying = true;
  bool _wasPlayingBeforePause = true;
  final String videoId = UniqueKey().toString();
  int _currentUrlIndex = 0;
  
  // Animation controllers for sound indicators
  late AnimationController _soundWaveController;
  late AnimationController _volumeBarController;
  late Animation<double> _soundWaveAnimation;
  late Animation<double> _volumeBarAnimation;

  @override
  bool get wantKeepAlive => _initialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controllers
    _soundWaveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _volumeBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _soundWaveAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _soundWaveController,
      curve: Curves.easeInOut,
    ));
    
    _volumeBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _volumeBarController,
      curve: Curves.easeOut,
    ));
    
    // Use playback settings from API - start unmuted for better user experience
    _isMuted = widget.playbackSettings?.muted ?? false;
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant AutoPlayVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay && _initialized && !_disposed) {
        if (_wasPlayingBeforePause) {
          _resumeVideo();
        }
      } else if (!widget.autoPlay && _initialized && !_disposed) {
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
              mixWithOthers: widget.playbackSettings?.playsInline ?? true,
              allowBackgroundPlayback: false,
            ),
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(currentUrl),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: widget.playbackSettings?.playsInline ?? true,
              allowBackgroundPlayback: false,
            ),
          );

    _controller!
      ..setLooping(widget.playbackSettings?.loop ?? true)
      ..setVolume(_isMuted ? 0.0 : 1.0)
      ..initialize().then((_) {
        _initTimer?.cancel();
        if (!_disposed && mounted) {
          setState(() {
            _initialized = true;
          });
          // Start sound animations if unmuted and playing
          if (!_isMuted && _isPlaying) {
            _startSoundAnimations();
          }
          // Auto-play based on API settings and widget autoPlay
          if (mounted && 
              widget.autoPlay && 
              _wasPlayingBeforePause && 
              (widget.playbackSettings?.autoplay ?? true)) {
            _controller!.play();
            _isPlaying = true;
            if (!_isMuted) {
              _startSoundAnimations();
            }
          }
        }
      }).catchError((error) {
        _initTimer?.cancel();
        if (!_disposed) {
          _tryNextUrl();
        }
      });
  }

  void _startSoundAnimations() {
    if (!_isMuted && _isPlaying) {
      _soundWaveController.repeat(reverse: true);
      _volumeBarController.forward();
    }
  }

  void _stopSoundAnimations() {
    _soundWaveController.stop();
    _soundWaveController.reset();
    _volumeBarController.reverse();
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
      _stopSoundAnimations();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resumeVideo() {
    if (_controller != null && _initialized && !_disposed) {
      _controller!.play();
      if (!_isMuted) {
        _startSoundAnimations();
      }
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
        _stopSoundAnimations();
        break;
      case AppLifecycleState.resumed:
        if (_initialized && mounted && _isPlaying && widget.autoPlay) {
          _controller!.play();
          if (!_isMuted) {
            _startSoundAnimations();
          }
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller!.pause();
        _stopSoundAnimations();
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _initTimer?.cancel();
    _soundWaveController.dispose();
    _volumeBarController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || _disposed) return;

    setState(() {
      _isPlaying = !_isPlaying;
      _wasPlayingBeforePause = _isPlaying;
      if (_isPlaying) {
        _controller!.play();
        if (!_isMuted) {
          _startSoundAnimations();
        }
      } else {
        _controller!.pause();
        _stopSoundAnimations();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || _disposed) return;

    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      
      if (_isMuted) {
        _stopSoundAnimations();
      } else if (_isPlaying) {
        _startSoundAnimations();
      }
    });
  }

  Widget _buildSoundWaveIndicator() {
    return AnimatedBuilder(
      animation: _soundWaveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double animationValue = (_soundWaveAnimation.value + delay) % 1.0;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 12 + (8 * animationValue),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVolumeBarIndicator() {
    return AnimatedBuilder(
      animation: _volumeBarAnimation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 4,
              height: 20 * _volumeBarAnimation.value,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
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
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade800,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepOrange,
                        ),
                      ),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.deepOrange,
                  ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                // Sound wave indicator when unmuted and playing
                if (!_isMuted && _isPlaying && _initialized)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          _buildSoundWaveIndicator(),
                          SizedBox(width: 6),
                          Text(
                            'SOUND ON',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Show controls if enabled in playback settings
                if (widget.playbackSettings?.controls ?? true)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: _isMuted 
                          ? null 
                          : Border.all(color: Colors.green.withOpacity(0.7), width: 2),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: _isMuted ? Colors.white : Colors.green,
                              size: 28,
                            ),
                            onPressed: _toggleMute,
                          ),
                          // Volume bar indicator
                          if (!_isMuted && _isPlaying)
                            Positioned(
                              right: 2,
                              top: 6,
                              child: _buildVolumeBarIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Expandable Status Text Widget
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

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 120);

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
    ); /// Initlizing the App the And o ro98z ro br  ibir n bdicrf j ihhsdf j   hro  iu zh  ejnichve 
  }
}