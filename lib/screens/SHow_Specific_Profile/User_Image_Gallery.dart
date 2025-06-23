import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:innovator/App_data/App_data.dart';
import 'dart:async';

class UserImageGallery extends StatefulWidget {
  final String userEmail;

  const UserImageGallery({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  _UserImageGalleryState createState() => _UserImageGalleryState();
}

class _UserImageGalleryState extends State<UserImageGallery> {
  final AppData _appData = AppData();
  List<String> _images = [];
  bool _isLoading = true;
  String? _error;
  String? _lastId; // Track last content ID for pagination
  bool _hasMoreImages = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce; // For debouncing scroll listener
  int _retryCount = 0; // For retry mechanism
  static const int _maxRetries = 3;
  static const double _loadTriggerThreshold = 500.0;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 200), () {
      if (!_isLoading &&
          _hasMoreImages &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - _loadTriggerThreshold) {
        _loadImages();
      }
    });
  }

  Future<void> _loadImages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _lastId = null;
        _images.clear();
        _hasMoreImages = true;
        _retryCount = 0;
      });
    }

    if (!_hasMoreImages && !refresh) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _makeApiRequest();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 200 && data['data'] != null) {
          final List<dynamic> posts = data['data']['contents'] ?? [];
          final List<String> newImages = [];
          String? newLastId;

          // Extract image URLs from posts by this user
          for (var post in posts) {
            if (post['author'] != null &&
                post['author']['email'] == widget.userEmail &&
                post['files'] != null &&
                post['files'] is List) {
              for (var file in post['files']) {
                if (file is String &&
                    file.isNotEmpty &&
                    _isImageFile(file)) {
                  newImages.add('http://182.93.94.210:3065$file');
                }
              }
              newLastId = post['_id']; // Update lastId to the last post's ID
            }
          }

          setState(() {
            _images.addAll(newImages);
            _isLoading = false;
            _lastId = newLastId ?? _lastId;
            _hasMoreImages = data['data']['hasMore'] ?? newImages.isNotEmpty;
            _retryCount = 0; // Reset retry count on success
            if (_images.isEmpty && !_hasMoreImages) {
              _error = 'No images available for this user.';
            }
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load images';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Authentication required. Please login.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load images: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on SocketException {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying request ($_retryCount/$_maxRetries)...');
        await Future.delayed(Duration(seconds: 2));
        await _loadImages(refresh: refresh); // Retry the request
      } else {
        setState(() {
          _error = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying request ($_retryCount/$_maxRetries)...');
        await Future.delayed(Duration(seconds: 2));
        await _loadImages(refresh: refresh); // Retry the request
      } else {
        setState(() {
          _error = 'Request timed out.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading images: $e';
        _isLoading = false;
      });
    }
  }

  bool _isImageFile(String file) {
    final lowerFile = file.toLowerCase();
    return lowerFile.endsWith('.jpg') ||
        lowerFile.endsWith('.jpeg') ||
        lowerFile.endsWith('.png') ||
        lowerFile.endsWith('.gif');
  }

  Future<http.Response> _makeApiRequest() async {
    final url = _lastId == null
        ? 'http://182.93.94.210:3065/api/v1/list-contents?email=${widget.userEmail}'
        : 'http://182.93.94.210:3065/api/v1/list-contents?lastId=$_lastId&email=${widget.userEmail}';

    debugPrint('Request URL: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'authorization': 'Bearer ${_appData.authToken}',
      },
    ).timeout(Duration(seconds: 30));
    debugPrint('Response: ${response.body}');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_error != null) {
      return _buildErrorView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              if (_images.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGallery(
                          images: _images,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_images.isEmpty && !_isLoading)
          _buildEmptyGallery(isDarkMode)
        else
          _buildImageGrid(isDarkMode),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_hasMoreImages && _images.isNotEmpty && !_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: OutlinedButton(
                onPressed: () => _loadImages(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Load More'),
              ),
            ),
          ),

      ],
    );
  }

  Widget _buildImageGrid(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _images.length > 9 ? 9 : _images.length,
        itemBuilder: (context, index) {
          final imageUrl = _images[index];

          return GestureDetector(
            onTap: () {
              _showFullScreenImage(imageUrl);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyGallery(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 60,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Images Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This user hasn\'t uploaded any images',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withAlpha(30)),
      ),
      child: Column(
        children: [
          Image.asset('animation/NoGallery.gif'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadImages(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenGalleryState createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}