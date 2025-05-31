import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Feed/OptimizeMediaScreen.dart';
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
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:share_plus/share_plus.dart'; // <-- Add this import


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
  final Author author;
  final DateTime createdAt;
  final DateTime updatedAt;
  int likes;
  int comments;
  bool isLiked;
  bool isFollowed;

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
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isFollowed = false,
  }) {
    try {
      _mediaUrls =
          files.map((file) {
            if (file.startsWith('http')) return file;
            return 'http://182.93.94.210:3064${file.startsWith('/') ? file : '/$file'}';
          }).toList();

      _hasImages = files.any((file) {
        final lowerFile = file.toLowerCase();
        return lowerFile.endsWith('.jpg') ||
            lowerFile.endsWith('.jpeg') ||
            lowerFile.endsWith('.png') ||
            lowerFile.endsWith('.gif');
      });

      _hasVideos = files.any((file) {
        final lowerFile = file.toLowerCase();
        return lowerFile.endsWith('.mp4') ||
            lowerFile.endsWith('.mov') ||
            lowerFile.endsWith('.avi');
      });

      _hasPdfs = files.any((file) => file.toLowerCase().endsWith('.pdf'));
      _hasWordDocs = files.any((file) {
        final lowerFile = file.toLowerCase();
        return lowerFile.endsWith('.doc') || lowerFile.endsWith('.docx');
      });
    } catch (e) {
      _mediaUrls = [];
      _hasImages = false;
      _hasVideos = false;
      _hasPdfs = false;
      _hasWordDocs = false;
      developer.log('Error initializing FeedContent media: $e');
    }
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    try {
      return FeedContent(
        id: json['_id'] ?? '',
        status: json['status'] ?? '',
        type: json['type'] ?? '',
        files: List<String>.from(json['files'] ?? []),
        author: Author.fromJson(
          json['author'] ??
              {'_id': '', 'name': 'Unknown', 'email': '', 'picture': ''},
        ),
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now(),
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'])
                : DateTime.now(),
        
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        isLiked: json['liked'] ?? false,
        isFollowed: json['followed'] ?? false,
      );
    } catch (e) {
      developer.log('Error parsing FeedContent: $e');
      return FeedContent(
        id: '',
        status: '',
        type: '',
        files: [],
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
}

class FileTypeHelper {
  static bool isImage(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.gif');
    } catch (e) {
      return false;
    }
  }

  static bool isVideo(String url) {
    try {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.mp4') ||
          lowerUrl.endsWith('.mov') ||
          lowerUrl.endsWith('.avi');
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

  final List<FeedContent> _contents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _lastId;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreData = true;
  static const _loadTriggerThreshold = 500.0;
  final AppData _appData = AppData();
  bool _isRefreshingToken = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initializeData() async {
    await _appData.initialize();
    _loadMoreContent();
  }

  void _scrollListener() {
    if (!_isLoading &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                _loadTriggerThreshold) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMoreData || _isRefreshingToken) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (!await _verifyToken()) {
        return;
      }

      final response = await _makeApiRequest();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _handleSuccessfulResponse(data);
      } else if (response.statusCode == 401) {
        await _handleUnauthorizedError();
      } else {
        _handleApiError(response.statusCode);
      }
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

  Future<bool> _verifyToken() async {
    if (_appData.authToken == null || _appData.authToken!.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Authentication required. Please login.';
      });
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }
    return true;
  }

  Future<http.Response> _makeApiRequest() async {
    final url =
        _lastId == null
            ? 'http://182.93.94.210:3064/api/v1/list-contents'
            : 'http://182.93.94.210:3064/api/v1/list-contents?lastId=$_lastId';

    debugPrint('Request URL: $url');
    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': 'Bearer ${_appData.authToken}',
          },
        )
        .timeout(Duration(seconds: 30));
    debugPrint('Response: ${response.body}');
    return response;
  }

  void _handleSuccessfulResponse(Map<String, dynamic> data) {
    if (data.containsKey('data') && data['data']['contents'] is List) {
      final List<dynamic> contentList = data['data']['contents'] as List;
      final List<FeedContent> newContents =
          contentList.map((item) => FeedContent.fromJson(item)).toList();

      setState(() {
        _contents.addAll(newContents);
        _lastId = newContents.isNotEmpty ? newContents.last.id : _lastId;
        _hasMoreData = data['data']['hasMore'] ?? false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid data format received from server';
      });
    }
  }

  Future<void> _handleUnauthorizedError() async {
    if (!_isRefreshingToken) {
      _isRefreshingToken = true;
      final success = await _refreshToken();
      _isRefreshingToken = false;

      if (success) {
        await _loadMoreContent();
      } else {
        await _appData.logout();
        Navigator.of(context).pushReplacementNamed('/login');
        setState(() {
          _hasError = true;
          _errorMessage = 'Session expired. Please login again.';
        });
      }
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/refresh-token'),
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
    // Implement your refresh token retrieval logic
    return null;
  }

  void _handleApiError(int statusCode) {
    setState(() {
      _hasError = true;
      _errorMessage = 'Server error: $statusCode';
    });
  }

  void _handleNetworkError() {
    setState(() {
      _hasError = true;
      _errorMessage = 'Network error. Please check your connection.';
    });
  }

  void _handleGenericError(dynamic e) {
    setState(() {
      _hasError = true;
      _errorMessage = 'Error: ${e.toString()}';
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _contents.clear();
      _lastId = null;
      _hasError = false;
      _hasMoreData = true;
    });
    await _loadMoreContent();
  }

  @override
  void dispose() {
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
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == _contents.length) {
                  return _buildLoadingIndicator();
                }
                return _buildContentItem(index);
              }, childCount: _contents.length + (_hasMoreData ? 1 : 0)),
            ),
            if (_hasError) SliverFillRemaining(child: _buildErrorView()),
            if (_contents.isEmpty && !_isLoading && !_hasError)
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
        onPressed: isLoading ? () {} : () async {
          try {
            print('FAB pressed! Current unread count: $unreadCount');


            if(unreadCount > 0)
            {
              chatController.resetAllUnreadCounts();
            }
            
            // Navigate to ChatListScreen
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
            
            // Refresh data when returning from chat screen
            print('Returned from ChatListScreen, refreshing data...');
            
            // Ensure controller is still available
            if (Get.isRegistered<ChatListController>()) {
              final controller = Get.find<ChatListController>();
              
              // Initialize MQTT if not connected
              if (!controller.isMqttConnected.value) {
                await controller.initializeMQTT();
              }
              
              // Fetch latest chats
              await controller.fetchChats();
              
              print('Chat data refreshed. New unread count: ${controller.totalUnreadCount}');
            }
          } catch (e) {
            print('Error in FAB onPressed: $e');
            Get.snackbar(
              'Error', 
              'Failed to open chat: $e',
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

       //FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder:
      //             (_) => ChatListScreen(
      //               currentUserId: AppData().currentUserId ?? '',
      //               currentUserName: AppData().currentUserName ?? '',
      //               currentUserPicture:
      //                   AppData().currentUserProfilePicture ?? '',
      //               currentUserEmail: AppData().currentUserEmail ?? '',
      //             ),
      //       ),
      //     );
      //   },
      //   child: Container(
      //     height: 200,
      //     width: 200,
      //     child: Lottie.asset('animation/chaticon.json'),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   elevation: 100.0,
      // ),
    );
  }

  Widget _buildContentItem(int index) {
    final content = _contents[index];
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage.contains('expired') ||
                      _errorMessage.contains('Authentication')
                  ? Icons.warning_amber
                  : Icons.error_outline,
              size: 48,
              color:
                  _errorMessage.contains('expired') ||
                          _errorMessage.contains('Authentication')
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            if (_errorMessage.contains('expired') ||
                _errorMessage.contains('Authentication'))
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Login'),
              )
            else
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Try Again'),
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
    baseUrl: 'http://182.93.94.210:3064',
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

  Future<void> _recordView() async {
    if (_hasRecordedView) return; // Prevent multiple calls
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

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/content/view/${widget.content.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer $authToken',
        },
      ).timeout( Duration(seconds: 100));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['message'] == 'View incremented') {
          developer.log('View recorded for content ID: ${widget.content.id}, Views: ${data['data']['views']}');
          // Optionally, update local state if view count is needed in UI
        } else {
          Get.snackbar(
            'Error',
            'Failed to record view: Invalid response',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Error',
          'Session expired. Please login again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Get.snackbar(
          'Error',
          'Failed to record view: ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error recording view: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      developer.log('Error recording view for content ID: ${widget.content.id}, Error: $e');
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
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Enhanced Avatar
              Hero(
                tag: 'avatar_${widget.content.author.id}',
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
                              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
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
                              color: _getTypeColor(widget.content.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              widget.content.type,
                              style: TextStyle(
                                color: _getTypeColor(widget.content.type),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                 fontFamily: 'Segoe UI'
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
              vertical: 16.0,
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
                          child: Text(
                            widget.content.status,
                            style: const TextStyle(
                              fontSize: 15.0,
                              height: 1.5,
                              color: Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w400,
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
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: _buildMediaPreview(),
            ),
          ),

        // Action Buttons Section
        Container(
          padding: const EdgeInsets.all(16.0),
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
                        _showComments ? Icons.chat_bubble : Icons.chat_bubble_outline,
                        color: _showComments ? Colors.blue.shade600 : Colors.grey.shade600,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '${widget.content.comments}',
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                _copyPostLink();
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
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
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
  Get.snackbar('Success', 'Post link copied to clipboard!', backgroundColor: Colors.green, colorText: Colors.white);

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
      final firstImageUrl = widget.content.mediaUrls
          .firstWhere((url) => FileTypeHelper.isImage(url), orElse: () => '');
      
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
    final textContent = widget.content.status.isNotEmpty 
        ? widget.content.status 
        : 'Check out this ${widget.content.type.toLowerCase()} by ${widget.content.author.name}';
    
    await Share.share(
      textContent,
      subject: 'Shared from App',
    );
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
      builder: (context) => const AlertDialog(
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
        subject: 'Check out this post with media by ${widget.content.author.name}',
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
  shareText.writeln('❤️ ${widget.content.likes} likes • 💬 ${widget.content.comments} comments');
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
    shareText.writeln('📸 Contains ${widget.content.files.where((f) => FileTypeHelper.isImage(f)).length} image(s)');
  }
  if (widget.content.hasVideos) {
    shareText.writeln('🎥 Contains ${widget.content.files.where((f) => FileTypeHelper.isVideo(f)).length} video(s)');
  }
  if (widget.content.hasPdfs) {
    shareText.writeln('📄 Contains PDF document(s)');
  }
  if (widget.content.hasWordDocs) {
    shareText.writeln('📝 Contains Word document(s)');
  }
  
  shareText.writeln();
  shareText.writeln('📅 ${_formatTimeAgo(widget.content.createdAt)}');
  shareText.writeln('❤️ ${widget.content.likes} likes • 💬 ${widget.content.comments} comments');
  shareText.writeln();
  shareText.writeln('View full post with media: ${_generatePostLink()}');
  
  return shareText.toString();
}

void _showShareError(String message) {
                Get.snackbar('Error', message, backgroundColor: Colors.red, colorText: Colors.white,       duration: const Duration(seconds: 3),);

  // ScaffoldMessenger.of(context).showSnackBar(
  //   SnackBar(
  //     content: Row(
  //       children: [
  //         const Icon(Icons.error_outline, color: Colors.white),
  //         const SizedBox(width: 8),
  //         Text(message),
  //       ],
  //     ),
  //     backgroundColor: Colors.red,
  //     duration: const Duration(seconds: 3),
  //   ),
  // );
}


  void _showQuickspecificSuggestions(BuildContext context) {
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

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(value: 'copy', child: Text('Copy content')),
        const PopupMenuItem<String>(value: 'report', child: Text('Report')),
      ],
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

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(value: 'edit', child: Text('Edit content')),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete post'),
        ),
        if (widget.content.files.isNotEmpty)
          const PopupMenuItem<String>(
            value: 'delete_files',
            child: Text('Delete files'),
          ),
        const PopupMenuItem<String>(value: 'copy', child: Text('Copy content')),
        const PopupMenuItem<String>(value: 'report', child: Text('Report')),
      ],
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Content'),
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
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateContentStatus(String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://182.93.94.210:3064/api/v1/update-contents/${widget.content.id}',
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
              Get.snackbar('Success', 'Content Updated Successfully', backgroundColor: Colors.green, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Content updated successfully')),
        // );
      } else {
              Get.snackbar('Error', 'Failed to update content: ${response.statusCode}', backgroundColor: Colors.red, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to update content: ${response.statusCode}'),
        //   ),
        // );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
          'http://182.93.94.210:3064/api/v1/delete-content/${widget.content.id}',
        ),
        headers: {'authorization': 'Bearer ${AppData().authToken}'},
      );

      if (response.statusCode == 200) {
                      Get.snackbar('Success', 'Post Deleted Successfully', backgroundColor: Colors.green, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Post deleted successfully')),
        // );
      } else {
                      Get.snackbar('Error', 'Failed to Delete Post: ${response.statusCode}', backgroundColor: Colors.red, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to delete post: ${response.statusCode}'),
        //   ),
        // );
      }
    } catch (e) {
            Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        Uri.parse('http://182.93.94.210:3064/api/v1/delete-files'),
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
                      Get.snackbar('Success', 'Files Delted Successfully', backgroundColor: Colors.green, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Files deleted successfully')),
        // );
      } else {
        Get.snackbar('Error', 'Failed to Delete Files: ${response.statusCode}', backgroundColor: Colors.red, colorText: Colors.white);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Failed to delete files: ${response.statusCode}'),
        //   ),
        // );
      }
    } catch (e) {

            Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _copyContentToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content.status));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content copied to clipboard')),
    );
  }

  void _showReportLinkButton(BuildContext context) {
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report Content'),
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

            // Validate input
            if (reason.isEmpty) {
              Get.snackbar('Error', 'Please provide a reason for reporting.', backgroundColor: Colors.red, colorText: Colors.white);

              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Please provide a reason for reporting.'),
              //     backgroundColor: Colors.red,
              //   ),
              // );
              return;
            }

            try {
              // Prepare API request
              final response = await http.post(
                Uri.parse('http://182.93.94.210:3064/api/v1/report'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'authorization': 'Bearer ${AppData().authToken}',
                },
                body: jsonEncode({
                  'reportedUserId': widget.content.author.id,
                  'reason': reason,
                  'description': description.isEmpty ? reason : description,
                }),
              );

              // Handle API response
              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                              Get.snackbar('Success', data['message'] ?? 'Your report has been submitted successfully.', backgroundColor: Colors.green, colorText: Colors.white);

                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text(
                //       data['message'] ?? 'Your report has been submitted successfully.',
                //     ),
                //     backgroundColor: Colors.green,
                //   ),
                // );
                Navigator.of(context).pop();
              } else {
                final data = json.decode(response.body);
                              Get.snackbar('Error', data['message'] ?? 'Failed to Submit Report: ${response.statusCode}', backgroundColor: Colors.red, colorText: Colors.white);

                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text(
                //       'Failed to submit report: ${data['message'] ?? 'Error ${response.statusCode}'}',
                //     ),
                //     backgroundColor: Colors.,
                //   ),
                // );
              }
            } catch (e) {
                    Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);

              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Error submitting report: ${e.toString()}'),
              //     backgroundColor: Colors.red,
              //   ),
              // );
            }
          },
          child: const Text('Submit'),
        ),
      ],
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
      imageUrl: 'http://182.93.94.210:3064${widget.content.author.picture}',
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
    );
  }

  Widget _buildMediaPreview() {
    final mediaUrls = widget.content.mediaUrls;

    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    if (mediaUrls.length == 1) {
      final fileUrl = mediaUrls.first;

      if (FileTypeHelper.isImage(fileUrl)) {
        return LimitedBox(
          maxHeight: 250.0,
          child: GestureDetector(
            onTap: () => _showMediaGallery(context, mediaUrls, 0),
            child: _OptimizedNetworkImage(url: fileUrl, height: 250.0),
          ),
        );
      } else if (FileTypeHelper.isVideo(fileUrl)) {
         return LimitedBox(
    maxHeight: 250.0,
    child: GestureDetector(
      onTap: () => _showMediaGallery(context, mediaUrls, 0),
      child: AutoPlayVideoWidget(url: fileUrl, height: 250.0),
    ),
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
                    color: Colors.black.withOpacity(0.5),
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
      memCacheWidth: (MediaQuery.of(context).size.width * 1.2).toInt(),
    );
  }
}

class FeedApiService {
  static const String baseUrl = 'http://182.93.94.210:3064';

  static Future<List<FeedContent>> fetchContents(String? lastId) async {
    try {
      final String? authToken = AppData().authToken;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['authorization'] = 'Bearer $authToken';
      }

      final url =
          lastId == null
              ? '$baseUrl/api/v1/list-contents'
              : '$baseUrl/api/v1/list-contents?lastId=$lastId';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data']['contents'] is List) {
          final List<dynamic> contentList = data['data']['contents'] as List;
          final List<FeedContent> contents = [];

          // Process each content item and fetch follow status
          for (var item in contentList) {
            final content = FeedContent.fromJson(item);
            try {
              // Fetch follow status for the author
              final isFollowing = await FollowService.checkFollowStatus(
                content.author.email,
              );
              contents.add(
                FeedContent(
                  id: content.id,
                  status: content.status,
                  type: content.type,
                  files: content.files,
                  author: content.author,
                  createdAt: content.createdAt,
                  updatedAt: content.updatedAt,
                  likes: content.likes,
                  comments: content.comments,
                  isLiked: content.isLiked,
                  isFollowed: isFollowing, // Set the follow status
                ),
              );
            } catch (e) {
              print(
                'Error checking follow status for ${content.author.email}: $e',
              );
              // Fallback to default isFollowed value if check fails
              contents.add(content);
            }
          }

          return contents;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      }

      throw Exception('Failed to load data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
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

  const AutoPlayVideoWidget({required this.url, this.height, this.width, Key? key}) : super(key: key);

  @override
  State<AutoPlayVideoWidget> createState() => _AutoPlayVideoWidgetState();
}

class _AutoPlayVideoWidgetState extends State<AutoPlayVideoWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
    bool _isMuted = false;


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
   if (!_initialized) {
      return Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _toggleMute,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 18,
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}