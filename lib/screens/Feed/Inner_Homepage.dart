import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
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
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

// VideoPlaybackManager class
class VideoPlaybackManager {
  static final VideoPlaybackManager _instance = VideoPlaybackManager._internal();
  factory VideoPlaybackManager() => _instance;
  VideoPlaybackManager._internal();

  final Set<AutoPlayVideoWidgetState> _registeredVideos = {};

  void registerVideo(AutoPlayVideoWidgetState video) {
    _registeredVideos.add(video);
  }

  void unregisterVideo(AutoPlayVideoWidgetState video) {
    _registeredVideos.remove(video);
  }

  void pauseAllVideos() {
    for (final video in _registeredVideos) {
      if (video.mounted) {
        video.pauseVideo();
      }
    }
  }

  void resumeAllVideos() {
    for (final video in _registeredVideos) {
      if (video.mounted) {
        video.playVideo();
      }
    }
  }
}

// Enhanced CacheManager class
class CacheManager {
  static const String _cacheKey = 'feed_cache';
  static const int _maxCacheSize = 100;
  static List<FeedContent> _memoryCache = [];
  
  static Future<void> cacheFeedContent(List<FeedContent> contents) async {
    try {
      _memoryCache.addAll(contents);
      
      if (_memoryCache.length > _maxCacheSize) {
        _memoryCache = _memoryCache.sublist(_memoryCache.length - _maxCacheSize);
      }
      
      debugPrint('Cached ${contents.length} feed items. Total cache size: ${_memoryCache.length}');
    } catch (e) {
      debugPrint('Error caching feed content: $e');
    }
  }
  
  static Future<List<FeedContent>> getCachedFeed() async {
    try {
      debugPrint('Retrieved ${_memoryCache.length} cached feed items');
      return List.from(_memoryCache);
    } catch (e) {
      debugPrint('Error getting cached feed: $e');
      return [];
    }
  }
  
  static void clearCache() {
    _memoryCache.clear();
    debugPrint('Feed cache cleared');
  }
}

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

// Enhanced FeedContent model
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
      final allUrls = [
        ...files.map((file) => _formatUrl(file)),
        ...optimizedFiles
            .where((file) => file['url'] != null)
            .map((file) => _formatUrl(file['url'])),
      ];

      _mediaUrls = allUrls.toSet().toList();

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
      return url;
    }
    return 'http://182.93.94.210:3066${url.startsWith('/') ? url : '/$url'}';
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

  String? get bestVideoUrl {
    try {
      final videoFiles =
          optimizedFiles.where((file) => file['type'] == 'video').toList();
      if (videoFiles.isEmpty) return null;

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

  String? get thumbnailUrl {
    try {
      for (final file in optimizedFiles) {
        if (file['thumbnail'] != null) {
          return _formatUrl(file['thumbnail']);
        }
      }

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
  final List<FeedContent> _allContents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _nextVideoCursor;
  String? _nextNormalCursor;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreVideos = true;
  bool _hasMoreNormal = true;
  final AppData _appData = AppData();
  bool _isRefreshingToken = false;
  bool _isOnline = true;
  Timer? _debounce;
  Timer? _autoLoadTimer;
  DateTime _lastLoadTime = DateTime.now();
  
  // Memory management
  static const int _maxContentItems = 200;
  static const int _contentToRemove = 50;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeData();
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
    _startAutoLoadTimer();
  }

  // ENHANCED AUTO LOAD TIMER - More aggressive loading
  void _startAutoLoadTimer() {
    _autoLoadTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_isLoading && 
          (_hasMoreVideos || _hasMoreNormal) && 
          _allContents.length < 30) { // Increased threshold
        debugPrint('🔄 Auto-loading more content. Current items: ${_allContents.length}');
        _loadMoreContent();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
      if (_isOnline) {
        _refresh();
      }
    } on SocketException catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      await _appData.initialize();
      if (await _verifyToken()) {
        await _loadMoreContent();
        
        // Load more content initially to ensure sufficient items
        if (_allContents.length < 20 && (_hasMoreVideos || _hasMoreNormal)) {
          await Future.delayed(Duration(milliseconds: 300));
          await _loadMoreContent();
        }
        
        // Third load if still insufficient
        if (_allContents.length < 15 && (_hasMoreVideos || _hasMoreNormal)) {
          await Future.delayed(Duration(milliseconds: 300));
          await _loadMoreContent();
        }
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (await _verifyToken()) {
        await _loadMoreContent();
      }
    }
  }

  // ENHANCED SCROLL LISTENER - More aggressive triggers
  void _scrollListener() {
    if (_debounce?.isActive ?? false) return;
    
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      
      final double currentPosition = _scrollController.position.pixels;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      
      // Multiple aggressive trigger points
      final threshold20 = maxScrollExtent * 0.2;  // Very early loading
      final threshold40 = maxScrollExtent * 0.4;  // Early loading
      final threshold60 = maxScrollExtent * 0.6;  // Medium loading
      final threshold80 = maxScrollExtent * 0.8;  // Late loading
      final nearBottom = maxScrollExtent - 100;   // Almost at bottom
      
      // Check if we need more content
      final hasLowContent = _allContents.length < 25;
      final isScrollingDown = currentPosition >= threshold20;
      
      bool shouldLoad = !_isLoading && 
                       (_hasMoreVideos || _hasMoreNormal) &&
                       maxScrollExtent > 0 &&
                       (isScrollingDown || hasLowContent);
      
      if (shouldLoad) {
        debugPrint('🔄 Scroll loading triggered - Position: ${currentPosition.toInt()}/${maxScrollExtent.toInt()}, Items: ${_allContents.length}');
        _loadMoreContent();
      }
    });
  }

  // ENHANCED LOAD MORE CONTENT - Better error handling and retry logic
  Future<void> _loadMoreContent() async {
    if (_isLoading) {
      debugPrint('⏳ Already loading, skipping...');
      return;
    }
    
    if (!_hasMoreNormal && !_hasMoreVideos) {
      debugPrint('🛑 No more content available');
      return;
    }
    
    if (_isRefreshingToken) {
      debugPrint('🔑 Token refresh in progress, skipping...');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _lastLoadTime = DateTime.now();

    // Retry logic
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        debugPrint('📡 Loading attempt ${retryCount + 1}/$maxRetries');
        
        if (!_isOnline) {
          final cachedContents = await CacheManager.getCachedFeed();
          setState(() {
            if (cachedContents.isNotEmpty) {
              _allContents.clear();
              _allContents.addAll(cachedContents);
              _hasMoreVideos = false;
              _hasMoreNormal = false;
            }
            _isLoading = false;
          });
          return;
        }

        if (!await _verifyToken()) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final contentData = await FeedApiService.fetchContents(
          videoCursor: _nextVideoCursor,
          normalCursor: _nextNormalCursor,
          context: context,
        );

        // Cache the content
        try {
          await CacheManager.cacheFeedContent([
            ...contentData.videoContents,
            ...contentData.normalContents,
          ]);
        } catch (e) {
          debugPrint('Cache error (non-critical): $e');
        }

        if (mounted) {
          setState(() {
            final newContents = <FeedContent>[];
            
            if (contentData.videoContents.isNotEmpty) {
              newContents.addAll(contentData.videoContents);
              debugPrint('✅ Added ${contentData.videoContents.length} video contents');
            }
            
            if (contentData.normalContents.isNotEmpty) {
              newContents.addAll(contentData.normalContents);
              debugPrint('✅ Added ${contentData.normalContents.length} normal contents');
            }
            
            _allContents.addAll(newContents);
            debugPrint('📊 Total feed items: ${_allContents.length}');
            
            // Memory management
            _manageMemory();
            
            _nextVideoCursor = contentData.nextVideoCursor;
            _nextNormalCursor = contentData.nextNormalCursor;
            
            _hasMoreVideos = contentData.hasMoreVideos;
            _hasMoreNormal = contentData.hasMoreNormal;
            
            debugPrint('🔄 Has more - Videos: $_hasMoreVideos, Normal: $_hasMoreNormal');
            
            _isLoading = false;
          });
        }

        // Break out of retry loop on success
        break;

      } catch (e, stackTrace) {
        retryCount++;
        debugPrint('❌ Error in _loadMoreContent attempt $retryCount: $e');
        
        if (retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.toString().contains('Authentication') || e.toString().contains('401')) {
                _hasError = true;
                _errorMessage = 'Please login again';
              } else {
                _hasError = true;
                _errorMessage = 'Failed to load content. Please try again.';
              }
            });
          }
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }
  }

  void _manageMemory() {
    if (_allContents.length > _maxContentItems) {
      final itemsToRemove = _allContents.length - (_maxContentItems - _contentToRemove);
      _allContents.removeRange(0, itemsToRemove);
      debugPrint('🧹 Memory management: Removed $itemsToRemove old content items');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          if (await Permission.notification.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      }

      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            criticalAlert: true,
            provisional: false,
          );

      if (Platform.isAndroid) {
        debugPrint(
          'Running on Android, please ensure battery optimization is disabled for Innovator',
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<bool> _verifyToken() async {
    try {
      if (_appData.authToken == null || _appData.authToken!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Authentication required. Please login.';
        });
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error verifying token: $e');
      return false;
    }
  }

  Future<void> _refresh() async {
    debugPrint('🔄 Refreshing feed...');
    setState(() {
      _allContents.clear();
      _nextVideoCursor = null;
      _nextNormalCursor = null;
      _hasError = false;
      _hasMoreVideos = true;
      _hasMoreNormal = true;
    });
    
    // Clear cache on refresh
    CacheManager.clearCache();
    
    await _loadMoreContent();
    
    // Load additional content after refresh
    if (_allContents.length < 15 && (_hasMoreVideos || _hasMoreNormal)) {
      await Future.delayed(Duration(milliseconds: 500));
      await _loadMoreContent();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autoLoadTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _allContents.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError && _allContents.isEmpty
                ? _buildErrorView()
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    cacheExtent: 2000.0, // Increased cache extent
                    itemCount: _allContents.length + 
                              (_isLoading ? 1 : 0) + 
                              (_shouldShowEndMessage() ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _allContents.length) {
                        return _buildContentItem(_allContents[index]);
                      }
                      
                      if (index == _allContents.length && _isLoading) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Center(child: CircularProgressIndicator()),
                              const SizedBox(height: 8),
                              Text(
                                'Loading more content...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (_shouldShowEndMessage() && index == _allContents.length + (_isLoading ? 1 : 0)) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'re all caught up!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total loaded: ${_allContents.length} posts',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
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

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatListScreen(
                              currentUserId: AppData().currentUserId ?? '',
                              currentUserName: AppData().currentUserName ?? '',
                              currentUserPicture:
                                  AppData().currentUserProfilePicture ?? '',
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
                        debugPrint('Error in FAB onPressed: $e');
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

  bool _shouldShowEndMessage() {
    return !_isLoading && 
           !_hasMoreVideos && 
           !_hasMoreNormal && 
           _allContents.isNotEmpty;
  }

  Widget _buildContentItem(FeedContent content) {
    return RepaintBoundary(
      key: ValueKey(content.id),
      child: FeedItem(
        content: content,
        onLikeToggled: (isLiked) {
          if (mounted) {
            setState(() {
              content.isLiked = isLiked;
              content.likes += isLiked ? 1 : -1;
            });
          }
        },
        onFollowToggled: (isFollowed) {
          if (mounted) {
            setState(() {
              content.isFollowed = isFollowed;
            });
          }
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Enhanced FeedApiService class
class FeedApiService {
  static const String baseUrl = 'http://182.93.94.210:3066';

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

      final params = <String, String>{
        'loadEngagement': 'true',
        'quality': 'auto',
        'limit': '30', // Increased limit for better loading
      };
      
      if (videoCursor != null && videoCursor.isNotEmpty) {
        params['videoCursor'] = videoCursor;
      }
      if (normalCursor != null && normalCursor.isNotEmpty) {
        params['normalCursor'] = normalCursor;
      }

      final uri = Uri.parse('$baseUrl/api/v1/list-contents')
          .replace(queryParameters: params);

      debugPrint('🌐 Fetching from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final contentResponse = ContentResponse.fromJson(data);

        if (contentResponse.status == 200) {
          final List<FeedContent> videoContents = [];
          final List<FeedContent> normalContents = [];

          // Process contents with reduced timeout
          for (var item in contentResponse.data.videoContents) {
            try {
              final isFollowing = await FollowService.checkFollowStatus(
                item.author.email,
              ).timeout(const Duration(seconds: 2));
              videoContents.add(item.copyWith(isFollowed: isFollowing));
            } catch (e) {
              videoContents.add(item);
            }
          }

          for (var item in contentResponse.data.normalContents) {
            try {
              final isFollowing = await FollowService.checkFollowStatus(
                item.author.email,
              ).timeout(const Duration(seconds: 2));
              normalContents.add(item.copyWith(isFollowed: isFollowing));
            } catch (e) {
              normalContents.add(item);
            }
          }

          debugPrint('✅ Fetched ${videoContents.length} videos, ${normalContents.length} normal contents');

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
          throw Exception('Invalid response status: ${contentResponse.status}');
        }
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        }
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FeedApiService error: $e');
      rethrow;
    }
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
    try {
      return ContentData(
        videoContents: (json['videoContents'] as List<dynamic>? ?? [])
            .map((item) {
              try {
                return FeedContent.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing video content: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<FeedContent>()
            .toList(),
        normalContents: (json['normalContents'] as List<dynamic>? ?? [])
            .map((item) {
              try {
                return FeedContent.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing normal content: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<FeedContent>()
            .toList(),
        hasMoreVideos: json['hasMoreVideos'] as bool? ?? true,
        hasMoreNormal: json['hasMoreNormal'] as bool? ?? true,
        nextVideoCursor: json['nextVideoCursor'] as String?,
        nextNormalCursor: json['nextNormalCursor'] as String?,
        optimizationInfo: json['optimizationInfo'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      debugPrint('Error parsing ContentData: $e');
      return ContentData(
        videoContents: [],
        normalContents: [],
        hasMoreVideos: true,
        hasMoreNormal: true,
        nextVideoCursor: null,
        nextNormalCursor: null,
        optimizationInfo: {},
      );
    }
  }
}

// FeedContent extension
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

// FeedItem Widget
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
  bool _hasRecordedView = false;

  late AnimationController _controller;
  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3066',
  );
  late String formattedTimeAgo;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    formattedTimeAgo = _formatTimeAgo(widget.content.createdAt);
    _recordView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Future<bool> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();

      return connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  Future<void> _recordView() async {
    if (_hasRecordedView) return;

    bool isConnected = await _checkConnectivity();
    if (!isConnected) return;

    _hasRecordedView = true;

    try {
      final String? authToken = AppData().authToken;
      if (authToken == null || authToken.isEmpty) return;

      final response = await http
          .post(
            Uri.parse(
              'http://182.93.94.210:3066/api/v1/content/view/${widget.content.id}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'authorization': 'Bearer $authToken',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['message'] == 'View incremented') {
          developer.log('View recorded for content ID: ${widget.content.id}');
        }
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _hasRecordedView = false;
      developer.log('Error recording view: $e');
    }
  }

  bool _isAuthorCurrentUser() {
    if (AppData().isCurrentUser(widget.content.author.id)) {
      return true;
    }

    final String? token = AppData().authToken;
    if (token != null && token.isNotEmpty) {
      try {
        final String? currentUserId = JwtHelper.extractUserId(token);
        if (currentUserId != null) {
          return currentUserId == widget.content.author.id;
        }
      } catch (e) {
        developer.log('Error parsing JWT token: $e');
      }
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
                  // Avatar
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

                  // Author Info
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                SpecificUserProfilePage(
                                  userId: widget.content.author.id,
                                ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                                    targetUserEmail: widget.content.author.email,
                                    initialFollowStatus: widget.content.isFollowed,
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
                                  color: _getTypeColor(widget.content.type).withAlpha(50),
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

                  // Menu Button
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like Button
                  _buildActionButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _showComments
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            color: _showComments
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
                            color: _showComments
                                ? Colors.blue.shade600
                                : Colors.grey.shade700,
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
              child: _showComments
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

  Widget _buildAuthorAvatar() {
    final userController = Get.find<UserController>();

    if (_isAuthorCurrentUser()) {
      return Obx(() {
        final picturePath = userController.getFullProfilePicturePath();
        final version = userController.profilePictureVersion.value;

        return CircleAvatar(
          key: ValueKey('feed_avatar_${widget.content.author.id}_$version'),
          backgroundImage: picturePath != null
              ? NetworkImage('$picturePath?v=$version')
              : null,
          child: picturePath == null || picturePath.isEmpty
              ? Text(
                  widget.content.author.name.isNotEmpty
                      ? widget.content.author.name[0].toUpperCase()
                      : '?',
                )
              : null,
        );
      });
    }

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
      imageUrl: 'http://182.93.94.210:3066${widget.content.author.picture}',
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(backgroundImage: imageProvider),
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
      return const SizedBox.shrink();
    }

    if (mediaUrls.length == 1) {
      final fileUrl = mediaUrls.first;

      if (FileTypeHelper.isImage(fileUrl)) {
        return LimitedBox(
          maxHeight: 450.0,
          child: GestureDetector(
            onTap: () => _showMediaGallery(context, mediaUrls, 0),
            child: _OptimizedNetworkImage(url: fileUrl, height: 250.0),
          ),
        );
      } else if (FileTypeHelper.isVideo(fileUrl)) {
        return FutureBuilder<Size>(
          future: _getVideoSize(fileUrl),
          builder: (context, snapshot) {
            double maxHeight = 250.0;
            if (snapshot.hasData) {
              final size = snapshot.data!;
              final aspectRatio = size.width / size.height;
              if (aspectRatio < 1) {
                maxHeight = 400.0;
              }
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
        return _buildDocumentPreview(
          fileUrl,
          'PDF Document',
          Icons.picture_as_pdf,
          Colors.red,
        );
      } else if (FileTypeHelper.isWordDoc(fileUrl)) {
        return _buildDocumentPreview(
          fileUrl,
          'Word Document',
          Icons.description,
          Colors.blue,
        );
      }
    }

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
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: _OptimizedNetworkImage(url: fileUrl),
                );
              } else if (FileTypeHelper.isVideo(fileUrl)) {
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, mediaUrls, index),
                  child: AutoPlayVideoWidget(url: fileUrl),
                );
              } else if (FileTypeHelper.isPdf(fileUrl)) {
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
        memCacheWidth: (MediaQuery.of(context).size.width * 1.5).toInt(),
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) =>
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
        builder: (context) => OptimizedMediaGalleryScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    final TextEditingController shareTextController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              TextField(
                controller: shareTextController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 10),
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

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/new-content'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "type": "share",
          "shareText": shareText,
        }),
      );

      Get.back();

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Post shared successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      debugPrint('Error sharing content: $e');
    }
  }

  void _shareViaApps() async {
    try {
      final shareText = 'Check out this post by ${widget.content.author.name}: ${widget.content.status}';
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing via apps: $e');
    }
  }

  void _showQuickSuggestions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete post'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('Copy content'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.content.status));
        Get.snackbar('Copied', 'Content copied to clipboard');
      }
    });
  }

  void _showQuickspecificSuggestions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.orange),
                title: const Text('Report'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.content.status));
        Get.snackbar('Copied', 'Content copied to clipboard');
      }
    });
  }
}

// AutoPlayVideoWidget with enhanced performance
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
  bool _isMuted = true;
  bool _disposed = false;
  Timer? _initTimer;
  bool _isPlaying = true;
  final String videoId = UniqueKey().toString();
  static final Map<String, AutoPlayVideoWidgetState> _activeVideos = {};

  @override
  bool get wantKeepAlive => true;

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) {
          setState(fn);
        }
      });
    }
  }

  void pauseVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.pause();
      _safeSetState(() {
        _isPlaying = false;
      });
    }
  }

  void playVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.play();
      _safeSetState(() {
        _isPlaying = true;
      });
    }
  }

  void muteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.setVolume(0.0).then((_) {
        _safeSetState(() {
          _isMuted = true;
        });
      }).catchError((error) {
        developer.log('Error muting video: $error');
      });
    }
  }

  void unmuteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.setVolume(1.0);
      _safeSetState(() {
        _isMuted = false;
      });
    }
  }

  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _initialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      ..setVolume(0.0)
      ..initialize().then((_) {
        _initTimer?.cancel();
        if (!_disposed) {
          _safeSetState(() {
            _initialized = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_disposed) {
              _controller!.play();
            }
          });
        }
      }).catchError((error) {
        _initTimer?.cancel();
        if (!_disposed) {
          _handleInitializationError();
        }
      });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _disposed || _controller == null) return;

    final visibleFraction = info.visibleFraction;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;

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
    });
  }

  void _muteOtherVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.key != videoId && entry.value.mounted && !entry.value._disposed) {
          entry.value._controller?.pause();
          entry.value._controller?.setVolume(0.0);
          entry.value._safeSetState(() {
            entry.value._isMuted = true;
            entry.value._isPlaying = false;
          });
        }
      }
    });
  }

  static void pauseAllAutoPlayVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.value.mounted && !entry.value._disposed) {
          entry.value._controller?.pause();
          entry.value._controller?.setVolume(0.0);
          entry.value._safeSetState(() {
            entry.value._isMuted = true;
            entry.value._isPlaying = false;
          });
        }
      }
    });
  }

  static void resumeAllAutoPlayVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.value._initialized && entry.value.mounted && !entry.value._disposed) {
          entry.value._controller?.play();
          entry.value._controller?.setVolume(0.0);
          entry.value._safeSetState(() {
            entry.value._isPlaying = true;
            entry.value._isMuted = true;
          });
        }
      }
    });
  }

  void _handleInitializationError([Object? error]) {
    _safeSetState(() {
      _initialized = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null || _disposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;

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
    });
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
    if (_controller == null || _disposed || !_initialized) return;

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
    if (_controller == null || _disposed || !_initialized) return;

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
            ? _buildLoadingOrThumbnail()
            : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildLoadingOrThumbnail() {
    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey,
          child: const Center(
            child: Icon(Icons.videocam_off, color: Colors.white),
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
  }

  Widget _buildVideoPlayer() {
    return LayoutBuilder(
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
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: targetWidth,
                  height: targetHeight,
                  child: VideoPlayer(_controller!),
                ),
              ),
              
              if (!_isPlaying)
                IgnorePointer(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
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
    );
  }
}

// OptimizedNetworkImage widget
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
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.error, color: Colors.white)),
      ),
      memCacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
      memCacheHeight: (MediaQuery.of(context).size.height * 2).toInt(),
    );
  }
}

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