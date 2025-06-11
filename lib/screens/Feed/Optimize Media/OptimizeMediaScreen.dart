import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/screens/Feed/Optimize%20Media/optimizeImage.dart';
import 'package:innovator/screens/Feed/Optimize%20Media/optimizeVideoPlayer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

class OptimizedMediaGalleryScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const OptimizedMediaGalleryScreen({
    required this.mediaUrls,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  @override
  _OptimizedMediaGalleryScreenState createState() => _OptimizedMediaGalleryScreenState();
}

class _OptimizedMediaGalleryScreenState extends State<OptimizedMediaGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullScreen = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _pdfLoadFailed = false;
  bool _isLoadingVideo = false;
  
  // Keep track of loaded items to improve memory usage
  final Set<int> _loadedIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // We'll move the media loading to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now it's safe to call methods that might use MediaQuery
    // Load current media
    _loadMedia(_currentIndex);
    
    // Preload adjacent media for smoother experience
    if (_currentIndex > 0) {
      _preloadMedia(_currentIndex - 1);
    }
    
    if (_currentIndex < widget.mediaUrls.length - 1) {
      _preloadMedia(_currentIndex + 1); 
    }
  }

  // Preload media without showing it
  void _preloadMedia(int index) {
    if (index < 0 || index >= widget.mediaUrls.length) return;
    if (_loadedIndices.contains(index)) return;
    
    _loadedIndices.add(index);
    final url = widget.mediaUrls[index];
    
    if (FileTypeHelper.isImage(url)) {
      precacheImage(NetworkImage(url), context);
    }
  }

  Future<void> _loadMedia(int index) async {
    if (index < 0 || index >= widget.mediaUrls.length) return;
    
    _loadedIndices.add(index);
    final url = widget.mediaUrls[index];
    
    if (FileTypeHelper.isVideo(url)) {
      await _initializeVideo(url);
    }
  }

  Future<void> _initializeVideo(String url) async {
    if (_isLoadingVideo) return;

    setState(() => _isLoadingVideo = true);

    try {
      // Clean up previous controllers
      await _videoController?.dispose();
      _chewieController?.dispose();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        allowFullScreen: false,
        errorBuilder: (context, errorMessage) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _downloadAndOpenFile(url, 'video.mp4'),
                child: const Text('Download and Open'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Video initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVideo = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${_currentIndex + 1}/${widget.mediaUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) async {
          setState(() {
            _currentIndex = index;
            _pdfLoadFailed = false;
          });

          // Load media only for the current page
          await _loadMedia(index);

          // Preload adjacent items
          if (index < widget.mediaUrls.length - 1) {
            _preloadMedia(index + 1);
          }
          if (index > 0) {
            _preloadMedia(index - 1);
          }
        },
        itemBuilder: (context, index) {
          // Only render the current page's media
          if (index != _currentIndex) {
            return Container(color: Colors.black);
          }
          final url = widget.mediaUrls[index];
          return GestureDetector(
            onTap: _toggleFullScreen,
            child: _buildMediaViewer(url),
          );
        },
      ),
    );
  }

  Widget _buildMediaViewer(String url) {
    if (FileTypeHelper.isImage(url)) {
      return _buildImageViewer(url);
    } else if (FileTypeHelper.isVideo(url)) {
      return _buildVideoViewer();
    } else if (FileTypeHelper.isPdf(url)) {
      return _buildPdfViewer(url);
    } else {
      return _buildUnsupportedViewer(url);
    }
  }

  Widget _buildImageViewer(String url) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 1.0,
      maxScale: 3.0,
      child: Center(
        child: OptimizedImage(
          url: url,
          fit: BoxFit.contain,
          placeholder: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: const Center(
            child: Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    return OptimizedVideoPlayer(
      url: widget.mediaUrls[_currentIndex],
      maxHeight: MediaQuery.of(context).size.height,
      onError: () {
        // Handle video error
        final url = widget.mediaUrls[_currentIndex];
        _downloadAndOpenFile(url, 'video.mp4');
      },
    );
  }

  Widget _buildPdfViewer(String url) {
    if (_pdfLoadFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load PDF',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _downloadAndOpenFile(url, 'document.pdf'),
              child: const Text('Download and Open'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.network(
          url,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _pdfLoadFailed = true;
            });
          },
          canShowScrollHead: false,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.download),
            onPressed: () => _downloadAndOpenFile(url, 'document.pdf'),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedViewer(String url) {
    // Get filename from URL
    final fileName = url.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    IconData icon;
    String fileType;
    
    if (fileExtension == 'doc' || fileExtension == 'docx') {
      icon = Icons.description;
      fileType = 'Word Document';
    } else {
      icon = Icons.insert_drive_file;
      fileType = 'Document';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            fileType,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _downloadAndOpenFile(url, fileName),
            child: const Text('Download and Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading file...'),
            ],
          ),
        ),
      );
      
      // Download file
      final response = await http.get(Uri.parse(url));
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Open file
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }
}