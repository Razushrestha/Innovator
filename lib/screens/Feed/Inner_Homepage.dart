import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/Feed/Optimize%20Media/OptimizeMediaScreen.dart';
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Feed/VideoPlayer/videoplayerpackage.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/screens/Likes/content-Like-Button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/screens/chatrrom/Screen/chat_listscreen.dart';
import 'package:innovator/screens/chatrrom/controller/chatlist_controller.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/screens/comment/comment_section.dart';
import 'package:innovator/widget/CustomizeFAB.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:share_plus/share_plus.dart'; // <-- Add this import
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Enhanced Author model
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

// Enhanced FeedContent model with better error handling
class FeedContent {
  final String id;
  String status;
  final String type;
  final List<String> files;
  final List<dynamic> optimizedFiles;
  final Author author;
  final DateTime createdAt;
  final DateTime updatedAt;
  int views;
  bool isShared;
  int likes;
  int comments;
  bool isLiked;
  bool isFollowed;
  bool engagementLoaded;
  String loadPriority;

  late final List<String> _mediaUrls;
  late final bool _hasImages;
  late final bool _hasVideos;
  late final bool _hasPdfs;
  late final bool _hasWordDocs;

  FeedContent({
    required this.id,
    required this.status,
    required this.type,
    required this.files,
    required this.optimizedFiles,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.isShared = false,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isFollowed = false,
    this.engagementLoaded = false,
    this.loadPriority = 'normal',
  }) {
    try {
      // Process both original files and optimized files
      final allUrls = [
        ...files.map((file) => _formatUrl(file)),
        ...optimizedFiles
            .where((file) => file['url'] != null)
            .map((file) => _formatUrl(file['url'])),
      ];

      _mediaUrls = allUrls.toSet().toList(); // Remove duplicates

      _hasImages =
          _mediaUrls.any((url) => FileTypeHelper.isImage(url)) ||
          optimizedFiles.any((file) => file['type'] == 'image');

      _hasVideos =
          _mediaUrls.any((url) => FileTypeHelper.isVideo(url)) ||
          optimizedFiles.any((file) => file['type'] == 'video');

      _hasPdfs =
          _mediaUrls.any((url) => FileTypeHelper.isPdf(url)) ||
          optimizedFiles.any((file) => file['type'] == 'pdf');

      _hasWordDocs = _mediaUrls.any((url) => FileTypeHelper.isWordDoc(url));
    } catch (e) {
      _mediaUrls = [];
      _hasImages = false;
      _hasVideos = false;
      _hasPdfs = false;
      _hasWordDocs = false;
      developer.log('Error initializing FeedContent media: $e');
    }
  }

  String _formatUrl(String url) {
    if (url.startsWith('http')) {
      developer.log('Using original URL: $url', name: 'FeedContent');
      return url;
    }
    final formatted =
        'http://182.93.94.210:3065${url.startsWith('/') ? url : '/$url'}';
    developer.log('Formatted URL: $formatted', name: 'FeedContent');
    return formatted;
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    try {
      return FeedContent(
        id: json['_id'] ?? '',
        status: json['status'] ?? '',
        type: json['type'] ?? 'innovation',
        files: List<String>.from(json['files'] ?? []),
        optimizedFiles: List<dynamic>.from(json['optimizedFiles'] ?? []),
        author: Author.fromJson(json['author'] ?? {}),
        createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] ?? DateTime.now().toIso8601String(),
        ),
        views: json['views'] ?? 0,
        isShared: json['isShared'] ?? false,
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        isLiked: json['liked'] ?? false,
        engagementLoaded: json['engagementLoaded'] ?? false,
        loadPriority: json['loadPriority'] ?? 'normal',
      );
    } catch (e) {
      developer.log('Error parsing FeedContent: $e');
      return FeedContent(
        id: '',
        status: '',
        type: '',
        files: [],
        optimizedFiles: [],
        author: Author(id: '', name: 'Error', email: '', picture: ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  List<String> get mediaUrls => _mediaUrls;
  bool get hasImages => _hasImages;
  bool get hasVideos => _hasVideos;
  bool get hasPdfs => _hasPdfs;
  bool get hasWordDocs => _hasWordDocs;

  // Get the best quality video URL from optimized files
  String? get bestVideoUrl {
    try {
      final videoFiles =
          optimizedFiles.where((file) => file['type'] == 'video').toList();
      if (videoFiles.isEmpty) return null;

      // Sort by quality (assuming qualities are in order)
      videoFiles.sort((a, b) {
        final aQualities = List<String>.from(a['qualities'] ?? []);
        final bQualities = List<String>.from(b['qualities'] ?? []);
        return bQualities.length.compareTo(aQualities.length);
      });

      return _formatUrl(
        videoFiles.first['url'] ?? videoFiles.first['hls'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  // Get thumbnail URL
  String? get thumbnailUrl {
    try {
      // First try to get from optimized files
      for (final file in optimizedFiles) {
        if (file['thumbnail'] != null) {
          return _formatUrl(file['thumbnail']);
        }
      }

      // Fallback to first image file
      final imageUrl = _mediaUrls.firstWhere(
        (url) => FileTypeHelper.isImage(url),
        orElse: () => '',
      );

      return imageUrl.isNotEmpty ? imageUrl : null;
    } catch (e) {
      return null;
    }
  }
}

class ContentResponse {
  final int status;
  final ContentData data;
  final dynamic error;
  final String message;

  ContentResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(
      status: json['status'] as int,
      data: ContentData.fromJson(json['data'] ?? {}),
      error: json['error'],
      message: json['message'] as String? ?? '',
    );
  }
}

class ContentData {
  final List<FeedContent> videoContents;
  final List<FeedContent> normalContents;
  final bool hasMoreVideos;
  final bool hasMoreNormal;
  final String? nextVideoCursor;
  final String? nextNormalCursor;
  final Map<String, dynamic> optimizationInfo;

  ContentData({
    required this.videoContents,
    required this.normalContents,
    required this.hasMoreVideos,
    required this.hasMoreNormal,
    this.nextVideoCursor,
    this.nextNormalCursor,
    required this.optimizationInfo,
  });

  factory ContentData.fromJson(Map<String, dynamic> json) {
    return ContentData(
      videoContents:
          (json['videoContents'] as List<dynamic>? ?? [])
              .map((item) => FeedContent.fromJson(item as Map<String, dynamic>))
              .toList(),
      normalContents:
          (json['normalContents'] as List<dynamic>? ?? [])
              .map((item) => FeedContent.fromJson(item as Map<String, dynamic>))
              .toList(),
      hasMoreVideos: json['hasMoreVideos'] as bool? ?? false,
      hasMoreNormal: json['hasMoreNormal'] as bool? ?? false,
      nextVideoCursor: json['nextVideoCursor'] as String?,
      nextNormalCursor: json['nextNormalCursor'] as String?,
      optimizationInfo: json['optimizationInfo'] as Map<String, dynamic>? ?? {},
    );
  }
}

class FileTypeHelper {
  static bool isImage(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.gif') ||
          lowerUrl.contains('_thumb.jpg');
    } catch (e) {
      return false;
    }
  }

  static bool isVideo(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.mp4') ||
          lowerUrl.endsWith('.mov') ||
          lowerUrl.endsWith('.avi') ||
          lowerUrl.endsWith('.m3u8');
    } catch (e) {
      return false;
    }
  }

  static bool isPdf(String url) {
    try {
      return url.toLowerCase().endsWith('.pdf');
    } catch (e) {
      return false;
    }
  }

  static bool isWordDoc(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx');
    } catch (e) {
      return false;
    }
  }
}

class Inner_HomePage extends StatefulWidget {
  const Inner_HomePage({Key? key}) : super(key: key);

  @override
  _Inner_HomePageState createState() => _Inner_HomePageState();
}

class _Inner_HomePageState extends State<Inner_HomePage> {
  final ChatListController chatController = Get.put(ChatListController());
  final List<FeedContent> _videoContents = [];
  final List<FeedContent> _normalContents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _nextVideoCursor;
  String? _nextNormalCursor;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreVideos = true;
  bool _hasMoreNormal = true;
  static const _loadTriggerThreshold = 500.0;
  final AppData _appData = AppData();
  bool _isRefreshingToken = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeData();
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _refresh();
      });
    } on SocketException catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _initializeData() async {
  await _appData.initialize();
  if (await _verifyToken()) {
    _loadMoreContent();
  }
}

  Timer? _debounce;

  void _scrollListener() {
  if (_debounce?.isActive ?? false) return;
  _debounce = Timer(const Duration(milliseconds: 200), () {
    if (!_isLoading &&
        (_hasMoreVideos || _hasMoreNormal) &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - _loadTriggerThreshold) {
      _loadMoreContent();
    }
  });
}

  Future<void> _loadMoreContent() async {
    if (_isLoading ||
        (!_hasMoreNormal && !_hasMoreVideos) ||
        _isRefreshingToken)
      return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (!_isOnline) {
        final cachedContents = await CacheManager.getCachedFeed();
        setState(() {
          if (cachedContents.isNotEmpty) {
            _videoContents.clear();
            _normalContents.clear();
            _videoContents.addAll(cachedContents.where((c) => c.hasVideos));
            _normalContents.addAll(cachedContents.where((c) => !c.hasVideos));
            _hasMoreVideos = false;
            _hasMoreNormal = false;
          }
        });
        return;
      }

      if (!await _verifyToken()) return;

      final contentData = await FeedApiService.fetchContents(
        videoCursor: _nextVideoCursor,
        normalCursor: _nextNormalCursor,
        context: context,
      );

      await CacheManager.cacheFeedContent([
        ...contentData.videoContents,
        ...contentData.normalContents,
      ]);

      setState(() {
        _videoContents.addAll(contentData.videoContents);
        _normalContents.addAll(contentData.normalContents);
        _nextVideoCursor = contentData.nextVideoCursor;
        _nextNormalCursor = contentData.nextNormalCursor;
        _hasMoreVideos = contentData.hasMoreVideos;
        _hasMoreNormal = contentData.hasMoreNormal;
      });
    } on SocketException {
      _handleNetworkError();
    } catch (e) {
      _handleGenericError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        developer.log('Notification permission status: $status');
        if (status.isDenied) {
          if (await Permission.notification.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      }

      // Request FCM permission
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            criticalAlert: true,
            provisional: false,
          );
      developer.log('FCM permission status: ${settings.authorizationStatus}');

      if (Platform.isAndroid) {
        developer.log(
          'Running on Android, please ensure battery optimization is disabled for Innovator',
        );
      }
    } catch (e) {
      developer.log('Error requesting notification permission: $e');
    }
  }

  Future<bool> _verifyToken() async {
    if (_appData.authToken == null || _appData.authToken!.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Authentication required. Please login.';
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
      return false;
    }
    return true;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3065/api/v1/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _appData.setAuthToken(data['accessToken']);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  Future<String?> _getRefreshToken() async {
    //return await SecureStorage().getRefreshToken(); // Or your actual storage method

    // Implement your refresh token retrieval logic
    return null;
  }

  void _handleApiError(int statusCode) {
    setState(() {
      _hasError = true;
      _errorMessage = 'Server error: $statusCode';
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    });
  }

  void _handleNetworkError() {
    setState(() {
      _hasError = true;

      //_errorMessage = 'Network error. Please check your connection.';
    });
    Lottie.asset('animation/Googlesignup.json', height: mq.height * .05);
  }

  void _handleGenericError(dynamic e) {
    setState(() {
      _hasError = true;
      //_errorMessage = 'Error: ${e.toString()}';
    });
    Lottie.asset('animation/No_Internet.json');
  }

  Future<void> _refresh() async {
    setState(() {
      _videoContents.clear();
      _normalContents.clear();
      _nextVideoCursor = null;
      _nextNormalCursor = null;
      _hasError = false;
      _hasMoreVideos = true;
      _hasMoreNormal = true;
    });
    await _loadMoreContent();
  }

  @override
  void dispose() {
_debounce?.cancel();
  _scrollController.dispose();
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _videoContents.length) {
                    return _buildContentItem(_videoContents[index]);
                  }
                  final normalIndex = index - _videoContents.length;
                  if (normalIndex < _normalContents.length) {
                    return _buildContentItem(_normalContents[normalIndex]);
                  }
                  return null;
                },
                childCount:
                    _videoContents.length +
                    _normalContents.length +
                    (_isLoading ? 1 : 0),
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_hasError) SliverFillRemaining(child: _buildErrorView()),
            if (_videoContents.isEmpty &&
                _normalContents.isEmpty &&
                !_isLoading &&
                !_hasError)
              SliverFillRemaining(child: _buildEmptyView()),
          ],
        ),
      ),
      floatingActionButton: GetBuilder<ChatListController>(
        init: () {
          // Ensure ChatListController is initialized
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
              onPressed:
                  isLoading
                      ? () {}
                      : () async {
                        try {
                          print(
                            'FAB pressed! Current unread count: $unreadCount',
                          );

                          if (unreadCount > 0) {
                            chatController.resetAllUnreadCounts();
                          }

                          // Navigate to ChatListScreen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatListScreen(
                                    currentUserId:
                                        AppData().currentUserId ?? '',
                                    currentUserName:
                                        AppData().currentUserName ?? '',
                                    currentUserPicture:
                                        AppData().currentUserProfilePicture ??
                                        '',
                                    currentUserEmail:
                                        AppData().currentUserEmail ?? '',
                                  ),
                            ),
                          );
                          // Refresh data when returning from chat screen
                          print(
                            'Returned from ChatListScreen, refreshing data...',
                          );
                          // Ensure controller is still available
                          if (Get.isRegistered<ChatListController>()) {
                            final controller = Get.find<ChatListController>();
                            // Initialize MQTT if not connected
                            if (!controller.isMqttConnected.value) {
                              await controller.initializeMQTT();
                            }
                            // Fetch latest chats
                            await controller.fetchChats();
                            print(
                              'Chat data refreshed. New unread count: ${controller.totalUnreadCount}',
                            );
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
              // Add subtle animation based on connection status
              animationDuration: Duration(
                milliseconds: isMqttConnected ? 300 : 500,
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildContentItem(FeedContent content) {
    return RepaintBoundary(
      key: ValueKey(content.id),
      child: FeedItem(
        content: content,
        onLikeToggled: (isLiked) {
          setState(() {
            content.isLiked = isLiked;
            content.likes += isLiked ? 1 : -1;
          });
        },
        onFollowToggled: (isFollowed) {
          setState(() {
            content.isFollowed = isFollowed;
          });
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        )
        : const SizedBox.shrink();
  }

  Widget _buildErrorView() {
    if (!_isOnline) {
      _refresh();
    }
    if (_isOnline) {
      _loadMoreContent();
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isOnline) ...[
              Lottie.asset('animation/No_Internet.json'),
              const Text('You\'re offline. ', style: TextStyle(fontSize: 16)),
            ] else ...[
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _errorMessage.contains('expired') ||
                              _errorMessage.contains('Authentication')
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                _checkConnectivity();
                _refresh();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('animation/No-Content.json'),
          const Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No content available'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class FeedItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool) onLikeToggled;
  final Function(bool) onFollowToggled;

  const FeedItem({
    Key? key,
    required this.content,
    required this.onLikeToggled,
    required this.onFollowToggled,
  }) : super(key: key);

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 3;
  bool _hasRecordedView = false; // Flag to prevent duplicate view API calls

  late AnimationController _controller;
  bool isChecked = false;

  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3065',
  );
  late String formattedTimeAgo;
  bool _showComments = false;

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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    formattedTimeAgo = _formatTimeAgo(widget.content.createdAt);
    _recordView(); // Call the view API when the widget is initialized
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();

      // Check if any connection is available (WiFi, Mobile, Ethernet)
      return connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      developer.log('Error checking connectivity: $e');
      return false;
    }
  }

  Future<void> _recordView() async {
    if (_hasRecordedView) return; // Prevent multiple calls

    // Check connectivity before making API call
    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      developer.log(
        'No internet connection. Skipping view recording for content ID: ${widget.content.id}',
      );

      return;
    }

    _hasRecordedView = true;

    try {
      final String? authToken = AppData().authToken;
      if (authToken == null || authToken.isEmpty) {
        Get.snackbar(
          'Error',
          'Authentication required to record view.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse(
              'http://182.93.94.210:3065/api/v1/content/view/${widget.content.id}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'authorization': 'Bearer $authToken',
            },
          )
          .timeout(Duration(seconds: 100));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['message'] == 'View incremented') {
          developer.log(
            'View recorded for content ID: ${widget.content.id}, Views: ${data['data']['views']}',
          );
        } else {
          log('Error Failed to record View');
        }
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      } else {
        log('Error${response.statusCode}');
      }
    } catch (e) {
      _hasRecordedView = false;
      developer.log(
        'Error recording view for content ID: ${widget.content.id}, Error: $e',
      );
    }
  }

  bool _isAuthorCurrentUser() {
    if (AppData().isCurrentUser(widget.content.author.id)) {
      developer.log('isAuthorCurrentUser: Matched via AppData');
      return true;
    }

    final String? token = AppData().authToken;
    if (token != null && token.isNotEmpty) {
      try {
        final String? currentUserId = JwtHelper.extractUserId(token);
        if (currentUserId != null) {
          final result = currentUserId == widget.content.author.id;
          developer.log(
            'isAuthorCurrentUser: JWT check, currentUserId=$currentUserId, authorId=${widget.content.author.id}, result=$result',
          );
          return result;
        } else {
          developer.log(
            'isAuthorCurrentUser: JWT token does not contain user ID',
          );
        }
      } catch (e) {
        developer.log('isAuthorCurrentUser: Error parsing JWT token: $e');
      }
    } else {
      developer.log('isAuthorCurrentUser: No auth token available');
    }
    return false;
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
            color: Colors.black.withAlpha(8),
            blurRadius: 20.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(4),
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
                  // Enhanced Avatar
                  Hero(
                    tag:
                        'avatar_${widget.content.author.id}_${_isAuthorCurrentUser() ? Get.find<UserController>().profilePictureVersion.value : 0}',
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

                  // Author Info
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SpecificUserProfilePage(
                                      userId: widget.content.author.id,
                                    ),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: animation.drive(
                                  Tween(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ),
                                ),
                                child: child,
                              );
                            },
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
                                    targetUserEmail:
                                        widget.content.author.email,
                                    initialFollowStatus:
                                        widget.content.isFollowed,
                                    onFollowSuccess: () {
                                      widget.onFollowToggled(true);
                                    },
                                    onUnfollowSuccess: () {
                                      widget.onFollowToggled(false);
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
                                  color: _getTypeColor(
                                    widget.content.type,
                                  ).withAlpha(50),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  widget.content.type,
                                  style: TextStyle(
                                    color: _getTypeColor(widget.content.type),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    fontFamily: 'Segoe UI',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                formattedTimeAgo,
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

                  // Modern Menu Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        if (_isAuthorCurrentUser()) {
                          _showQuickSuggestions(context);
                        } else {
                          _showQuickspecificSuggestions(context);
                        }
                      },
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

            // Content Section
            if (widget.content.status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
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
                                maxLines:
                                    _isExpanded ? null : _maxLinesCollapsed,
                                overflow:
                                    _isExpanded ? null : TextOverflow.ellipsis,
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

            // Media Section
            if (widget.content.files.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: _buildMediaPreview(),
                ),
              ),

            // Action Buttons Section
            Container(
              // padding: const EdgeInsets.all(.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like Button
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

                  // Comment Button
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

                  // Share Button
                  _buildActionButton(
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.grey.shade600,
                      size: 20.0,
                    ),
                    onTap: () {
                      _showShareOptions(context);
                    },
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

  // Helper method for content type colors
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'post':
        return Colors.blue.shade600;
      case 'photo':
        return Colors.green.shade600;
      case 'video':
        return Colors.red.shade600;
      case 'story':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showShareOptions(BuildContext context) {
    final TextEditingController shareTextController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
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
                  // Add comment field for sharing within app
                  TextField(
                    controller: shareTextController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  // Share options
                  _buildShareOption(
                    icon: Icons.link,
                    title: 'Copy Link',
                    subtitle: 'Copy post link to clipboard',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _shareContent(shareTextController.text);
                    },
                  ),

                  _buildShareOption(
                    icon: Icons.share,
                    title: 'Share via Apps',
                    subtitle: 'Share using other apps',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _shareViaApps();
                    },
                  ),

                  _buildShareOption(
                    icon: Icons.text_snippet,
                    title: 'Share Text Only',
                    subtitle: 'Share post content as text',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _shareTextOnly();
                    },
                  ),

                  if (widget.content.files.isNotEmpty)
                    _buildShareOption(
                      icon: Icons.photo,
                      title: 'Share with Media',
                      subtitle: 'Include images/videos',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _shareWithMedia();
                      },
                    ),

                  const SizedBox(height: 10),

                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _shareContent(String? shareText) async {
    try {
      final String? authToken = AppData().authToken;
      if (authToken == null || authToken.isEmpty) {
        Get.snackbar(
          'Error',
          'Authentication required to share content',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3065/api/v1/new-content'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "type": "share",
          "originalContentId": widget.content.id,
          "shareText": shareText,
        }),
      );

      // Hide loading indicator
      Get.back();

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Post shared successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final data = json.decode(response.body);
        print('Error$data');
        // Get.snackbar(
        //   'Error',
        //   data['message'] ?? 'Failed to share post',
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );
      }
    } catch (e) {
      Get.back();
      print('Error${e.toString()}');
      // Get.snackbar(
      //   'Error',
      //   e.toString(),
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  // Share implementation methods:

  void _copyPostLink() {
    // Generate a shareable link for the post
    final postLink = _generatePostLink();

    Clipboard.setData(ClipboardData(text: postLink));
    Get.snackbar(
      'Success',
      'Post link copied to clipboard!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Row(
    //       children: [
    //         Icon(Icons.check_circle, color: Colors.white),
    //         SizedBox(width: 8),
    //         Text('Post link copied to clipboard!'),
    //       ],
    //     ),
    //     backgroundColor: Colors.green,
    //     duration: Duration(seconds: 2),
    //   ),
    // );
  }

  void _shareViaApps() async {
    try {
      final shareText = _buildShareText();

      if (widget.content.files.isNotEmpty && widget.content.hasImages) {
        // If there are images, try to share with the first image
        final firstImageUrl = widget.content.mediaUrls.firstWhere(
          (url) => FileTypeHelper.isImage(url),
          orElse: () => '',
        );

        if (firstImageUrl.isNotEmpty) {
          // For sharing with image, you might need to download it first
          await Share.share(
            shareText,
            subject: 'Check out this post by ${widget.content.author.name}',
          );
        } else {
          await Share.share(
            shareText,
            subject: 'Check out this post by ${widget.content.author.name}',
          );
        }
      } else {
        await Share.share(
          shareText,
          subject: 'Check out this post by ${widget.content.author.name}',
        );
      }
    } catch (e) {
      _showShareError('Failed to share post');
    }
  }

  void _shareTextOnly() async {
    try {
      final textContent =
          widget.content.status.isNotEmpty
              ? widget.content.status
              : 'Check out this ${widget.content.type.toLowerCase()} by ${widget.content.author.name}';

      await Share.share(textContent, subject: 'Shared from App');
    } catch (e) {
      _showShareError('Failed to share text');
    }
  }

  void _shareWithMedia() async {
    try {
      if (widget.content.files.isEmpty) {
        _shareTextOnly();
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Preparing media...'),
                ],
              ),
            ),
      );

      try {
        // For now, share text with media URLs
        // In a full implementation, you'd download and share actual files
        final shareText = _buildShareTextWithMedia();

        Navigator.pop(context); // Close loading dialog

        await Share.share(
          shareText,
          subject:
              'Check out this post with media by ${widget.content.author.name}',
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        throw e;
      }
    } catch (e) {
      _showShareError('Failed to share media');
    }
  }

  // Helper methods:

  String _generatePostLink() {
    // Generate a deep link or web link to the post
    // This would typically be your app's URL scheme or web URL
    return 'https://innovator.com/post/${widget.content.id}';
  }

  String _buildShareText() {
    final StringBuffer shareText = StringBuffer();

    shareText.writeln('📱 Shared from ${widget.content.author.name}');
    shareText.writeln();

    if (widget.content.status.isNotEmpty) {
      shareText.writeln(widget.content.status);
      shareText.writeln();
    }

    shareText.writeln('📅 ${_formatTimeAgo(widget.content.createdAt)}');
    shareText.writeln(
      '❤️ ${widget.content.likes} likes • 💬 ${widget.content.comments} comments',
    );
    shareText.writeln();
    shareText.writeln('View full post: ${_generatePostLink()}');

    return shareText.toString();
  }

  String _buildShareTextWithMedia() {
    final StringBuffer shareText = StringBuffer();

    shareText.writeln('📱 Shared from ${widget.content.author.name}');
    shareText.writeln();

    if (widget.content.status.isNotEmpty) {
      shareText.writeln(widget.content.status);
      shareText.writeln();
    }

    // Add media info
    if (widget.content.hasImages) {
      shareText.writeln(
        '📸 Contains ${widget.content.files.where((f) => FileTypeHelper.isImage(f)).length} image(s)',
      );
    }
    if (widget.content.hasVideos) {
      shareText.writeln(
        '🎥 Contains ${widget.content.files.where((f) => FileTypeHelper.isVideo(f)).length} video(s)',
      );
    }
    if (widget.content.hasPdfs) {
      shareText.writeln('📄 Contains PDF document(s)');
    }
    if (widget.content.hasWordDocs) {
      shareText.writeln('📝 Contains Word document(s)');
    }

    shareText.writeln();
    shareText.writeln('📅 ${_formatTimeAgo(widget.content.createdAt)}');
    shareText.writeln(
      '❤️ ${widget.content.likes} likes • 💬 ${widget.content.comments} comments',
    );
    shareText.writeln();
    shareText.writeln('View full post with media: ${_generatePostLink()}');

    return shareText.toString();
  }

  void _showShareError(String message) {
    Get.back;
    // Get.snackbar(
    //   'Error',
    //   message,
    //   backgroundColor: Colors.red,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 3),
    // );
    print('Error$message');
  }

  void _showQuickspecificSuggestions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
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
                  onTap: () {
                    Navigator.pop(context, 'copy');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context, 'report');
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'copy':
          _copyContentToClipboard();
          break;
        case 'report':
          _showReportLinkButton(context);
          break;
      }
    });
  }

  void _showQuickSuggestions(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.topRight(Offset(-40, 0)),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.topRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
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
                  leading: const Icon(Icons.edit, color: Color(0xFFF48706)),
                  title: const Text('Edit content'),
                  onTap: () {
                    Navigator.pop(context, 'edit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete post'),
                  onTap: () {
                    Navigator.pop(context, 'delete');
                  },
                ),
                if (widget.content.files.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.attach_file,
                      color: Colors.purple,
                    ),
                    title: const Text('Delete files'),
                    onTap: () {
                      Navigator.pop(context, 'delete_files');
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blue),
                  title: const Text('Copy content'),
                  onTap: () {
                    Navigator.pop(context, 'copy');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context, 'report');
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'edit':
          _showEditContentDialog(context);
          break;
        case 'delete':
          _showDeleteConfirmation(context);
          break;
        case 'delete_files':
          _showDeleteFilesConfirmation(context);
          break;
        case 'copy':
          _copyContentToClipboard();
          break;
        case 'report':
          _showReportLinkButton(context);
          break;
      }
    });
  }

  void _showEditContentDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: widget.content.status,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.transparent,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Edit Content',
                  style: TextStyle(
                    color: Color(0xFFF48706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _updateContentStatus(controller.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Color(0xFFF48706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Future<void> _updateContentStatus(String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://182.93.94.210:3065/api/v1/update-contents/${widget.content.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AppData().authToken}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.content.status = newStatus;
        });
        Get.snackbar(
          'Success',
          'Content Updated Successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.back();
        log('Error Failed to update content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error${e.toString()}');
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  _deleteContent();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteContent() async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://182.93.94.210:3065/api/v1/delete-content/${widget.content.id}',
        ),
        headers: {'authorization': 'Bearer ${AppData().authToken}'},
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Post Deleted Successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        log('Failed to Delete Post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error${e.toString()}');
    }
  }

  Future<bool?> _showDeleteFilesConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Files'),
            content: const Text(
              'Are you sure you want to delete all files attached to this post?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  _deleteFiles();
                },
                child: const Text(
                  'Delete Files',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteFiles() async {
    try {
      final response = await http.post(
        Uri.parse('http://182.93.94.210:3065/api/v1/delete-files'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AppData().authToken}',
        },
        body: jsonEncode(widget.content.files),
      );

      if (response.statusCode == 200) {
        setState(() {
          (widget.content as dynamic).files = <String>[];
        });
        Get.snackbar(
          'Success',
          'Files Delted Successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to Delete Files: ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _copyContentToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content.status));
    Get.snackbar(
      'Copied',
      'Content copied to clipboard',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    // ScaffoldMessenger.of(context).showSnackBar(
    //   Get.SnackBar(content: Text('')),
    // );
  }

  void _showReportLinkButton(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withAlpha(40),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: Colors.transparent,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Report Content',
                  style: TextStyle(
                    color: Color(0xFFF48706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Please tell us why you are reporting this content:',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                          hintText: 'Enter the reason for reporting',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Provide additional details (optional)',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final reason = reasonController.text.trim();
                      final description = descriptionController.text.trim();

                      if (reason.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please provide a reason for reporting.',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      try {
                        final response = await http.post(
                          Uri.parse('http://182.93.94.210:3065/api/v1/report'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'authorization': 'Bearer ${AppData().authToken}',
                          },
                          body: jsonEncode({
                            'reportedUserId': widget.content.author.id,
                            'reason': reason,
                            'description':
                                description.isEmpty ? reason : description,
                          }),
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          Get.snackbar(
                            'Success',
                            data['message'] ??
                                'Your report has been submitted successfully.',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          Navigator.of(context).pop();
                        } else {
                          final data = json.decode(response.body);
                          Get.snackbar(
                            'Error',
                            data['message'] ??
                                'Failed to Submit Report: ${response.statusCode}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          e.toString(),
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Color(0xFFF48706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Widget _buildAuthorAvatar() {
    final userController = Get.find<UserController>();

    // Check if this is the current user's post
    if (_isAuthorCurrentUser()) {
      return Obx(() {
        final picturePath = userController.getFullProfilePicturePath();
        final version = userController.profilePictureVersion.value;

        return GestureDetector(
          onTap: () {
            _showBigAvatarDialog(
              context,
              picturePath != null ? '$picturePath?v=$version' : null,
              widget.content.author.name,
            );
          },
          child: CircleAvatar(
            key: ValueKey(
              'feed_avatar_${widget.content.author.id}_$version',
            ), // Force rebuild
            backgroundImage:
                picturePath != null
                    ? NetworkImage(
                      '$picturePath?v=$version',
                    ) // Add version parameter
                    : null,
            child:
                picturePath == null || picturePath.isEmpty
                    ? Text(
                      widget.content.author.name.isNotEmpty
                          ? widget.content.author.name[0].toUpperCase()
                          : '?',
                    )
                    : null,
          ),
        );
      }); // initilizing Get in the code
    }

    // For other users' posts
    if (widget.content.author.picture.isEmpty) {
      return GestureDetector(
        onTap: () {
          _showBigAvatarDialog(context, null, widget.content.author.name);
        },
        child: CircleAvatar(
          child: Text(
            widget.content.author.name.isNotEmpty
                ? widget.content.author.name[0].toUpperCase()
                : '?',
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showBigAvatarDialog(
          context,
          'http://182.93.94.210:3065${widget.content.author.picture}',
          widget.content.author.name,
        );
      },
      child: CachedNetworkImage(
        imageUrl: 'http://182.93.94.210:3065${widget.content.author.picture}',
        imageBuilder:
            (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider),
        placeholder:
            (context, url) => const CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
        errorWidget:
            (context, url, error) => CircleAvatar(
              child: Text(
                widget.content.author.name.isNotEmpty
                    ? widget.content.author.name[0].toUpperCase()
                    : '?',
              ),
            ),
      ),
    );
  }

  // ...existing code...
  void _showBigAvatarDialog(
    BuildContext context,
    String? imageUrl,
    String name,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow tap outside to dismiss
      builder:
          (context) => GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Dismiss on tap outside
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  // Prevent dialog from closing when tapping the avatar itself
                  child:
                      imageUrl == null
                          ? CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.blue.shade200,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 60,
                                color: Colors.white,
                              ),
                            ),
                          )
                          : CachedNetworkImage(
                            imageUrl: imageUrl,
                            imageBuilder:
                                (context, imageProvider) => CircleAvatar(
                                  radius: 120,
                                  backgroundImage: imageProvider,
                                ),
                            placeholder:
                                (context, url) => const CircleAvatar(
                                  radius: 120,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => CircleAvatar(
                                  radius: 120,
                                  backgroundColor: Colors.blue.shade200,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildMediaPreview() {
    final hasOptimizedVideo = widget.content.optimizedFiles.any(
      (f) => f['type'] == 'video',
    );
    final hasOptimizedImages = widget.content.optimizedFiles.any(
      (f) => f['type'] == 'image',
    );

    if (hasOptimizedVideo) {
      final videoFile = widget.content.optimizedFiles.firstWhere(
        (f) => f['type'] == 'video');

      final videoUrl = videoFile['hls'] ?? videoFile['url'] ?? videoFile['original'];
      if (videoUrl != null) {
        return _buildVideoPreview(videoUrl);
      }
    }

    if (hasOptimizedImages) {
      final imageUrls =
          widget.content.optimizedFiles
              .where((f) => f['type'] == 'image')
    .map((file) => file['original'] ?? file['url'] ?? file['thumbnail'])
              .where((url) => url != null)
    .map((url) => widget.content._formatUrl(url))
              .toList();

      if (imageUrls.isNotEmpty) {
        return _buildImageGallery(imageUrls);
      }
    }

    final mediaUrls = widget.content.mediaUrls;

    if (mediaUrls.isEmpty) {
      developer.log(
        'No media URLs found for content ID: ${widget.content.id}',
        name: 'MediaPreview',
      );
      return const SizedBox.shrink();
    }

    developer.log(
      'Processing ${mediaUrls.length} media URLs for content ID: ${widget.content.id}',
      name: 'MediaPreview',
    );

    if (mediaUrls.length == 1) {
      final fileUrl = mediaUrls.first;

      if (FileTypeHelper.isImage(fileUrl)) {
        developer.log(
          'Loading single image: $fileUrl',
          name: 'MediaPreview.Image',
        );
        return LimitedBox(
          maxHeight: 450.0,
          child: GestureDetector(
            onTap: () => _showMediaGallery(context, mediaUrls, 0),
            child: _OptimizedNetworkImage(url: fileUrl, height: 250.0),
          ),
        );
      } else if (FileTypeHelper.isVideo(fileUrl)) {
        developer.log(
          'Loading single video: $fileUrl',
          name: 'MediaPreview.Video',
        );
        // Portrait video detection and display
        return FutureBuilder<Size>(
          future: _getVideoSize(fileUrl),
          builder: (context, snapshot) {
            double maxHeight = 250.0;
            double? aspectRatio;
            if (snapshot.hasData) {
              final size = snapshot.data!;
              aspectRatio = size.width / size.height;
              developer.log(
                'Video size retrieved: width=${size.width}, height=${size.height}, aspectRatio=$aspectRatio',
                name: 'MediaPreview.Video',
              );
              // Portrait if height > width (aspectRatio < 1)
              if (aspectRatio < 1) {
                maxHeight = 400.0; // Taller for portrait videos
              }
            } else if (snapshot.hasError) {
              developer.log(
                'Error retrieving video size for $fileUrl: ${snapshot.error}',
                name: 'MediaPreview.Video',
                error: snapshot.error,
              );
            }
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: LimitedBox(
                maxHeight: maxHeight,
                child: GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, 0),
                  child: AutoPlayVideoWidget(url: fileUrl, height: maxHeight),
                ),
              ),
            );
          },
        );
      } else if (FileTypeHelper.isPdf(fileUrl)) {
        developer.log('Loading single PDF: $fileUrl', name: 'MediaPreview.PDF');
        return _buildDocumentPreview(
          fileUrl,
          'PDF Document',
          Icons.picture_as_pdf,
          Colors.red,
        );
      } else if (FileTypeHelper.isWordDoc(fileUrl)) {
        developer.log(
          'Loading single Word document: $fileUrl',
          name: 'MediaPreview.WordDoc',
        );
        return _buildDocumentPreview(
          fileUrl,
          'Word Document',
          Icons.description,
          Colors.blue,
        );
      }
    }

    developer.log(
      'Building grid view for ${mediaUrls.length} media items',
      name: 'MediaPreview.Grid',
    );
    return LimitedBox(
      maxHeight: 300.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: mediaUrls.length > 4 ? 4 : mediaUrls.length,
            itemBuilder: (context, index) {
              final fileUrl = mediaUrls[index];

              if (index == 3 && mediaUrls.length > 4) {
                developer.log(
                  'Showing +${mediaUrls.length - 4} more items overlay',
                  name: 'MediaPreview.Grid',
                );
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: Container(
                    color: Colors.black.withAlpha(50),
                    child: Center(
                      child: Text(
                        '+${mediaUrls.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (FileTypeHelper.isImage(fileUrl)) {
                developer.log(
                  'Loading grid image at index $index: $fileUrl',
                  name: 'MediaPreview.Image',
                );
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: _OptimizedNetworkImage(url: fileUrl),
                );
              } else if (FileTypeHelper.isVideo(fileUrl)) {
                developer.log(
                  'Loading grid video at index $index: $fileUrl',
                  name: 'MediaPreview.Video',
                );
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: AutoPlayVideoWidget(url: fileUrl),
                );
              } else if (FileTypeHelper.isPdf(fileUrl)) {
                developer.log(
                  'Loading grid PDF at index $index: $fileUrl',
                  name: 'MediaPreview.PDF',
                );
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 32,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              } else if (FileTypeHelper.isWordDoc(fileUrl)) {
                developer.log(
                  'Loading grid Word document at index $index: $fileUrl',
                  name: 'MediaPreview.WordDoc',
                );
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.description,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              }

              developer.log(
                'Loading unknown file type at index $index: $fileUrl',
                name: 'MediaPreview.Unknown',
              );
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.insert_drive_file,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

 Widget _buildVideoPreview(String url) {
  // Try to get the original MP4 URL from optimizedFiles
  final originalVideoUrl = widget.content.optimizedFiles
      .where((file) => file['type'] == 'video')
      .map((file) => file['original'] ?? file['hls'] ?? file['url'])
      .firstWhere((url) => url != null, orElse: () => null);

  final videoUrl = originalVideoUrl ?? url;
  
  return Container(
    color: Colors.black,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: AutoPlayVideoWidget(
        url: widget.content._formatUrl(videoUrl),
        thumbnailUrl: widget.content.thumbnailUrl,
      ),
    ),
  );
}

  Widget _buildSingleImage(String url) {
    return GestureDetector(
      onTap: () => _showMediaGallery(context, [url], 0),
      child: CachedNetworkImage(
      filterQuality: FilterQuality.high,
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: (MediaQuery.of(context).size.width * 1.5).toInt(), // Reduce cache size for grid
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) =>
                Container(color: Colors.grey[300], child: Icon(Icons.error)),
      ),
    );
  }

  Widget _buildImageGallery(List<String> urls) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: urls.length > 1 ? 2 : 1,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
        childAspectRatio: 1.0,
      ),
      itemCount: urls.length > 4 ? 4 : urls.length,
      itemBuilder: (context, index) {
        if (index == 3 && urls.length > 4) {
          return GestureDetector(
            onTap: () => _showMediaGallery(context, urls, index),
            child: Container(
              color: Colors.black.withAlpha(50),
              child: Center(
                child: Text(
                  '+${urls.length - 4}',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
          );
        }
        return _buildSingleImage(urls[index]);
      },
    );
  }

  // Helper to get video size (width/height) using VideoPlayerController
  Future<Size> _getVideoSize(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    final size = controller.value.size;
    controller.dispose();
    return size;
  }

  Widget _buildDocumentPreview(
    String fileUrl,
    String label,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showMediaGallery(context, [fileUrl], 0),
      child: Container(
        height: 180.0,
        width: double.infinity,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaGallery(
    BuildContext context,
    List<String> mediaUrls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OptimizedMediaGalleryScreen(
              mediaUrls: mediaUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }
}

class _OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double? height;

  const _OptimizedNetworkImage({required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error, color: Colors.white)),
          ),
      memCacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
        memCacheHeight: (MediaQuery.of(context).size.height * 2).toInt(), // Added height cache

    );
  }
}

// Replace your existing FeedApiService class
class FeedApiService {
  static const String baseUrl = 'http://182.93.94.210:3065';

  static Future<ContentData> fetchContents({
    String? videoCursor,
    String? normalCursor,
    required BuildContext context,
  }) async {
    try {
      final String? authToken = AppData().authToken;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['authorization'] = 'Bearer $authToken';
      }

      final params = {
        'loadEngagement': 'true',
        'quality': 'auto',
        'limit': '20', // Add limit parameter
        if (videoCursor != null) 'videoCursor': videoCursor,
        if (normalCursor != null) 'normalCursor': normalCursor,
      };

      final uri = Uri.parse(
        '$baseUrl/api/v1/list-contents?',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final contentResponse = ContentResponse.fromJson(data);

        if (contentResponse.status == 200) {
          final List<FeedContent> videoContents = [];
          final List<FeedContent> normalContents = [];

          // Process video contents
          for (var item in contentResponse.data.videoContents) {
            try {
              final isFollowing = await FollowService.checkFollowStatus(
                item.author.email,
              );
              videoContents.add(item.copyWith(isFollowed: isFollowing));
            } catch (e) {
              print(
                'Error checking follow status for ${item.author.email}: $e',
              );
              videoContents.add(item);
            }
          }

          // Process normal contents
          for (var item in contentResponse.data.normalContents) {
            try {
              final isFollowing = await FollowService.checkFollowStatus(
                item.author.email,
              );
              normalContents.add(item.copyWith(isFollowed: isFollowing));
            } catch (e) {
              print(
                'Error checking follow status for ${item.author.email}: $e',
              );
              normalContents.add(item);
            }
          }

          return ContentData(
            videoContents: videoContents,
            normalContents: normalContents,
            hasMoreVideos: contentResponse.data.hasMoreVideos,
            hasMoreNormal: contentResponse.data.hasMoreNormal,
            nextVideoCursor: contentResponse.data.nextVideoCursor,
            nextNormalCursor: contentResponse.data.nextNormalCursor,
            optimizationInfo: contentResponse.data.optimizationInfo,
          );
        } else {
          throw Exception('Invalid response structure');
        }
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
        throw Exception('Authentication required');
      }

      throw Exception('Failed to load data: ${response.statusCode}');
    } catch (e) {
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => LoginPage()),
      //   (route) => false,
      // );
      throw Exception('Error: $e');
    }
  }
}

// Add this extension to FeedContent if not already present
extension FeedContentExtension on FeedContent {
  FeedContent copyWith({
    String? id,
    String? status,
    String? type,
    List<String>? files,
    List<dynamic>? optimizedFiles,
    Author? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? views,
    bool? isShared,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isFollowed,
    bool? engagementLoaded,
    String? loadPriority,
  }) {
    return FeedContent(
      id: id ?? this.id,
      status: status ?? this.status,
      type: type ?? this.type,
      files: files ?? this.files,
      optimizedFiles: optimizedFiles ?? this.optimizedFiles,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
      isShared: isShared ?? this.isShared,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
      engagementLoaded: engagementLoaded ?? this.engagementLoaded,
      loadPriority: loadPriority ?? this.loadPriority,
    );
  }
}

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

class AutoPlayVideoWidget extends StatefulWidget {
  final String url;
  final double? height;
  final double? width;
  final String? thumbnailUrl;

  const AutoPlayVideoWidget({
    required this.url,
    this.thumbnailUrl,

    this.height,
    this.width,
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

  @override
  bool get wantKeepAlive => true;

  // Public methods to control the video from outside
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
      _controller!
          .setVolume(0.0)
          .then((_) {
            if (mounted) {
              setState(() {
                _isMuted = true;
              });
              developer.log(
                'Video muted successfully for ID: $videoId',
                name: 'AutoPlayVideoWidget',
              );
            }
          })
          .catchError((error) {
            developer.log(
              'Error muting video for ID: $videoId: $error',
              name: 'AutoPlayVideoWidget',
            );
          });
    } else {
      developer.log(
        'Cannot mute video for ID: $videoId (controller null or disposed)',
        name: 'AutoPlayVideoWidget',
      );
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

    _initializeVideoPlayer();
    VideoPlaybackManager().registerVideo(this);
    _activeVideos[videoId] = this;
  }

  void _initializeVideoPlayer() {
    if (_disposed) return;

    _initTimer = Timer(const Duration(seconds: 30), () {
      if (!_initialized && !_disposed) {
        _handleInitializationError();
      }
    });

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    _controller!
      ..setLooping(true)
      ..setVolume(0.0) // Start muted
      ..initialize()
          .then((_) {
            _initTimer?.cancel();
            if (!_disposed && mounted) {
              setState(() {
                _initialized = true;
              });
              if (mounted) {
                _controller!.play();
              }
            }
          })
          .catchError((error) {
            _initTimer?.cancel();
            if (!_disposed) {
              _handleInitializationError();
            }
          });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _disposed || _controller == null) return;

    // Don't auto-play if gallery is open

    final visibleFraction = info.visibleFraction;

    if (visibleFraction > 0.5) {
      // Video is mostly visible
      _activeVideos[videoId] = this;
      _muteOtherVideos();
      if (_initialized && !_controller!.value.isPlaying && _isPlaying) {
        _controller!.play();
      }
    } else {
      // Video is mostly hidden
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

  // Static method to pause and mute all AutoPlay videos
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

  // Static method to resume all AutoPlay videos with their previous states
  static void resumeAllAutoPlayVideos() {
    for (final entry in _activeVideos.entries) {
      if (entry.value._initialized && entry.value.mounted) {
        entry.value._controller?.play();
        entry.value._isPlaying = true;
        // Keep them muted by default for auto-play behavior
        entry.value._controller?.setVolume(0.0);
        entry.value._isMuted = true;
        entry.value.setState(() {});
      }
    }
  }

  void _handleInitializationError([Object? error]) {
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
    VideoPlaybackManager().unregisterVideo(this);
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
        child:
            !_initialized || _controller == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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
                          if (_controller != null && _initialized)
                            VideoPlayer(_controller!),
                           (_controller == null || !_initialized) ? widget.thumbnailUrl != null ?
                            CachedNetworkImage(
                              imageUrl: widget.thumbnailUrl ?? '',
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      Container(color: Colors.grey),
                            ) :  Center(child: Icon(Icons.videocam_off)) :
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
                              child: Container(color: Colors.transparent),
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

// This is Used For Status For adding Link
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
          style:
              style?.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ) ??
              const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
          recognizer:
              TapGestureRecognizer()
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
//using 