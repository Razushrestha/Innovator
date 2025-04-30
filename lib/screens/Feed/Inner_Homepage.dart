import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/screens/Feed/OptimizeMediaScreen.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/screens/Likes/content-Like-Button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:innovator/screens/comment/comment_section.dart';

// Author model
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

// Model for API response data
class FeedContent {
  final String id;
  final String status;
  final String type;
  final List<String> files;
  final Author author;
  final DateTime createdAt;
  final DateTime updatedAt;
  int likes;
  int comments;
  bool isLiked;

  // Add these cached properties to avoid repeated calculations
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
  }) {
    // Initialize cached properties
    _mediaUrls = files.map((file) => 'http://182.93.94.210:3064$file').toList();

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

    _hasPdfs = files.any((file) {
      final lowerFile = file.toLowerCase();
      return lowerFile.endsWith('.pdf');
    });

    _hasWordDocs = files.any((file) {
      final lowerFile = file.toLowerCase();
      return lowerFile.endsWith('.doc') || lowerFile.endsWith('.docx');
    });
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
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
    );
  }

  // Get all media URLs - now returns cached value
  List<String> get mediaUrls => _mediaUrls;

  // Optimized getters that use cached values
  bool get hasImages => _hasImages;
  bool get hasVideos => _hasVideos;
  bool get hasPdfs => _hasPdfs;
  bool get hasWordDocs => _hasWordDocs;
}

// Helper class to determine file types efficiently
class FileTypeHelper {
  static bool isImage(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif');
  }

  static bool isVideo(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi');
  }

  static bool isPdf(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  static bool isWordDoc(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx');
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

  // For pagination optimization
  bool _hasMoreData = true;
  static const _loadTriggerThreshold =
      500.0; // Load more content when 500px from bottom

  @override
  void initState() {
    super.initState();
    _loadMoreContent();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Only fetch more data if we have more to fetch and not already loading
    if (!_isLoading &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                _loadTriggerThreshold) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://182.93.94.210:3064/api/v1/list-contents/$_currentPage',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> contentList = data['data'];
          final List<FeedContent> newContents =
              contentList.map((item) => FeedContent.fromJson(item)).toList();

          setState(() {
            _contents.addAll(newContents);
            _currentPage++;
            _isLoading = false;

            // Check if we got fewer items than expected (usually means we're at the end)
            if (newContents.isEmpty || newContents.length < 10) {
              // Assuming page size is 10
              _hasMoreData = false;
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Invalid data format received from server';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
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
        child:
            _hasError
                ? _buildErrorView()
                : _contents.isEmpty && !_isLoading
                ? _buildEmptyView()
                : _buildContentList(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Try Again')),
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

  Widget _buildContentList() {
    return ListView.builder(
      controller: _scrollController,
      // Use cacheExtent to keep more items in memory
      cacheExtent: 500.0,
      itemCount: _contents.length + (_hasMoreData ? 1 : 0),
      // Using itemBuilder with key for better list item identification
      itemBuilder: (context, index) {
        if (index == _contents.length) {
          return _isLoading
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
              : const SizedBox.shrink();
        }

        final content = _contents[index];

        // Using RepaintBoundary to optimize painting operations
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
          ),
        );
      },
    );
  }
}

// Extracted feed item into separate stateful widget to improve performance
class FeedItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool) onLikeToggled;

  const FeedItem({Key? key, required this.content, required this.onLikeToggled})
    : super(key: key);

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem> {
  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://182.93.94.210:3064',
  );
  late String formattedTimeAgo;
  bool _showComments = false; // Add this at the top of the state class

  @override
  void initState() {
    super.initState();

    formattedTimeAgo = _formatTimeAgo(widget.content.createdAt);
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

  @override
  Widget build(BuildContext context) {
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
          // Author section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildAuthorAvatar(),
                const SizedBox(width: 12.0),
                Expanded(
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
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show more options
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
              child: Text(
                widget.content.status,
                style: const TextStyle(fontSize: 15.0),
              ),
            ),

          // Media content preview - only build if there are files
          if (widget.content.files.isNotEmpty) _buildMediaPreview(),

          // Interaction buttons
          // In your FeedItem build method, modify the interaction buttons and comment section like this:

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
              if (_showComments) {
                print('Showing comments for content: ${widget.content.id}');
              } else {
                print('Hiding comments for content: ${widget.content.id}');
              }
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
        print('New comment added, refreshing comment count...');
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

// Optimized network image component
class _OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double? height;

  const _OptimizedNetworkImage({required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    // Use a late initializer for anything that needs MediaQuery
    // so it's only called inside build()
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
      // Move this to a late initializer, only reference MediaQuery inside build
      memCacheWidth: (MediaQuery.of(context).size.width * 1.2).toInt(),
    );
  }
}

// Additional Page for viewing all media in a post
class AllMediaScreen extends StatelessWidget {
  final List<String> mediaUrls;

  const AllMediaScreen({required this.mediaUrls, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Media'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          final url = mediaUrls[index];

          if (FileTypeHelper.isImage(url)) {
            return GestureDetector(
              onTap: () => _openGallery(context, index),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
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
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                    ),
              ),
            );
          } else if (FileTypeHelper.isVideo(url)) {
            return GestureDetector(
              onTap: () => _openGallery(context, index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32.0,
                    ),
                  ),
                ],
              ),
            );
          } else if (FileTypeHelper.isPdf(url)) {
            return GestureDetector(
              onTap: () => _openGallery(context, index),
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
          } else if (FileTypeHelper.isWordDoc(url)) {
            return GestureDetector(
              onTap: () => _openGallery(context, index),
              child: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.description, size: 32, color: Colors.blue),
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => _openGallery(context, index),
            child: Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.insert_drive_file,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGallery(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OptimizedMediaGalleryScreen(
              mediaUrls: mediaUrls,
              initialIndex: index,
            ),
      ),
    );
  }
}

// API service class for better separation of concerns
class FeedApiService {
  static const String baseUrl = 'http://182.93.94.210:3064';

  // Fetch feed contents with pagination
  static Future<List<FeedContent>> fetchContents(int page) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/list-contents/$page'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> contentList = data['data'];
          return contentList.map((item) => FeedContent.fromJson(item)).toList();
        }
      }

      throw Exception('Failed to load data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Toggle like status for a post
  // static Future<bool> toggleLike(String contentId, bool isLiking) async {
  //   try {
  //     final endpoint = isLiking ? '/api/v1/like-content' : '/api/v1/unlike-content';

  //     final response = await http.post(
  //       Uri.parse('$baseUrl$endpoint'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Accept': 'application/json',
  //       },
  //       body: json.encode({
  //         'contentId': contentId,
  //       }),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // Add a comment to a post
  static Future<bool> addComment(String contentId, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/add-comment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'contentId': contentId, 'comment': comment}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Extensions for better code organization
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
