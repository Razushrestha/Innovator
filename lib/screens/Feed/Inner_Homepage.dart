import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Feed/OptimizeMediaScreen.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/screens/Likes/content-Like-Button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/screens/comment/comment_section.dart';
import 'dart:io'; // For SocketException

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
  bool isFollowed; // Added followed property

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
    this.isFollowed = false, // Initialize followed property
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
      // Fallback values if parsing fails
      _mediaUrls = [];
      _hasImages = false;
      _hasVideos = false;
      _hasPdfs = false;
      _hasWordDocs = false;
    }
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    try {
      return FeedContent(
        id: json['_id'] ?? '',
        status: json['status'] ?? '',
        type: json['type'] ?? '',
        files: List<String>.from(json['files'] ?? []),
        author: Author.fromJson(json['author'] ?? {}),
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
        isFollowed: json['followed'] ?? false, // Parse followed property
      );
    } catch (e) {
      // Return empty content if parsing fails
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
  final List<FeedContent> _contents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
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
    // Wait for AppData to initialize if needed
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
      // Verify token exists and is valid
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
    }
  }

  Future<bool> _verifyToken() async {
    if (_appData.authToken == null || _appData.authToken!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Authentication required. Please login.';
      });
      return false;
    }
    return true;
  }

  Future<http.Response> _makeApiRequest() async {
    return await http.get(
      Uri.parse('http://182.93.94.210:3064/api/v1/list-contents/$_currentPage'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'authorization': 'Bearer ${_appData.authToken}',
      },
    );
  }

  void _handleSuccessfulResponse(Map<String, dynamic> data) {
    if (data.containsKey('data') && data['data'] is List) {
      final List<dynamic> contentList = data['data'];
      final List<FeedContent> newContents =
          contentList.map((item) => FeedContent.fromJson(item)).toList();

      setState(() {
        _contents.addAll(newContents);
        _currentPage++;
        _isLoading = false;
        _hasMoreData = newContents.isNotEmpty && newContents.length >= 10;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid data format received from server';
      });
    }
  }

  Future<void> _handleUnauthorizedError() async {
    // Try to refresh token first
    if (!_isRefreshingToken) {
      _isRefreshingToken = true;
      final success = await _refreshToken();
      _isRefreshingToken = false;

      if (success) {
        await _loadMoreContent();
        return;
      }
    }

    // If token refresh fails or not attempted
    await _appData.clearAuthToken();
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Session expired. Please login again.';
    });
  }

  Future<bool> _refreshToken() async {
    // Implement your token refresh logic here
    // This is a placeholder - replace with your actual refresh endpoint
    try {
      final refreshToken =
          await _getRefreshToken(); // You need to implement this
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/refresh-token'),
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
    // This typically comes from secure storage
    return null;
  }

  void _handleApiError(int statusCode) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Server error: $statusCode';
    });
  }

  void _handleNetworkError() {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Network error. Please check your connection.';
    });
  }

  void _handleGenericError(dynamic e) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Error: ${e.toString()}';
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _contents.clear();
      _currentPage = 0;
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
              //FloatingActionButton(onPressed: (){},   child: Image.asset('assets/message.gif'),)
          ],
        ),
      ),
floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          // Add your action here
          debugPrint('FloatingActionButton pressed!');
          // You could show a dialog, navigate to a new screen, etc.
        },
        child: Image.asset(
          'assets/images/message.gif', fit: BoxFit.fitHeight,),
        tooltip: 'Message',
      ),
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Check if the post author is the current user
  bool _isAuthorCurrentUser() {
    // Primary check using AppData's isCurrentUser method
    if (AppData().isCurrentUser(widget.content.author.id)) {
      return true;
    }
    
    // Secondary check using JWT token (as a fallback)
    final String? token = AppData().authToken;
    if (token != null && token.isNotEmpty) {
      final String? currentUserId = JwtHelper.extractUserId(token);
      return currentUserId == widget.content.author.id;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Check if author is current user
    final bool isOwnContent = _isAuthorCurrentUser();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.0), // Add some space at the top
          // Author section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildAuthorAvatar(),
                const SizedBox(width: 12.0),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SpecificUserProfilePage(
                                userId: widget.content.author.id,
                              ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.content.author.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        Text(
                          '${widget.content.type} • $formattedTimeAgo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Only show the Follow button if it's not the current user's content
                if (!isOwnContent)
                  FollowButton(
                    targetUserEmail: widget.content.author.email,
                    initialFollowStatus: widget.content.isFollowed,
                    onFollowSuccess: () {
                      widget.onFollowToggled(true);
                    },
                    onUnfollowSuccess: () {
                      widget.onFollowToggled(false);
                    },
                  ),

                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showQuickSuggestions(context);
                  },
                ),
              ],
            ),
          ),

          // Status/description text
          if (widget.content.status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Create a TextSpan with the same text style as your Text widget
                      final span = TextSpan(
                        text: widget.content.status,
                        style: const TextStyle(fontSize: 15.0),
                      );

                      // Use a TextPainter to determine if the text will overflow
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
                          Text(
                            widget.content.status,
                            style:  TextStyle(fontSize: 16.0, fontFamily: 'Segoe UI', letterSpacing: 0.5),
                            maxLines: _isExpanded ? null : _maxLinesCollapsed,
                            overflow:
                                _isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (needsExpandCollapse)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Text(
                                _isExpanded ? 'Show Less' : 'Show More',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
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
          // Media content preview - only build if there are files
          if (widget.content.files.isNotEmpty) _buildMediaPreview(),

          // Interaction buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      contentId: widget.content.id,
                      initialLikeStatus: widget.content.isLiked,
                      likeService: likeService,
                      onLikeToggled: (isLiked) {
                        widget.onLikeToggled(isLiked);
                      },
                    ),
                    Text('${widget.content.likes}'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                      icon: Icon(
                        _showComments ? Icons.comment : Icons.comment_outlined,
                        color: _showComments ? Colors.blue : null,
                      ),
                    ),
                    Text('${widget.content.comments}'),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    // Share content
                  },
                ),
              ],
            ),
          ),

          // Add the CommentSection outside the Row but inside the parent Column
          if (_showComments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CommentSection(
                contentId: widget.content.id,
                onCommentAdded: () {
                  setState(() {
                    widget.content.comments++;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showQuickSuggestions(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Calculate position relative to the overlay
    final RelativeRect position = RelativeRect.fromRect(
      // Use the button's top-right corner as the reference point
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
          _showReportDialog(context);
          break;
      }
    });
  }

  // Add these methods to handle each action:

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update content: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
        // You might want to refresh the feed here or remove this item
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
          // Clear files in the local content object
          (widget.content as dynamic).files = <String>[];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete files: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _copyContentToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content.status));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content copied to clipboard')),
    );
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Content'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please tell us why you are reporting this content:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Here you would add the code to send the report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your report has been submitted'),
                    ),
                  );
                  Navigator.of(context).pop();
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

    // If there's only one file
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
            child: Container(
              height: 250.0,
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 64.0,
                ),
              ),
            ),
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

    // If there are multiple files - use LimitedBox to constrain height
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

              // Show remaining count if there are more than 4 files
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
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 32.0,
                      ),
                    ),
                  ),
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

  // Fetch feed contents with pagination
  static Future<List<FeedContent>> fetchContents(int page) async {
    try {
      // Get auth token from AppData if available
      final String? authToken = AppData().authToken;

      // Prepare headers with auth token if available
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/list-contents/$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> contentList = data['data'];
          return contentList.map((item) => FeedContent.fromJson(item)).toList();
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized access - token might be expired
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

// Create a new file: lib/services/app_data.dart
