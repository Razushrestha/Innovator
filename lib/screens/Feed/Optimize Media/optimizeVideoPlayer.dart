import 'dart:async';

import 'package:flutter/material.dart';
import 'package:innovator/screens/Feed/Services/MediaService.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class OptimizedVideoPlayer extends StatefulWidget {
  final String url;
  final double? maxHeight;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final VoidCallback? onError;

  const OptimizedVideoPlayer({
    required this.url,
    this.maxHeight,
    this.autoPlay = true,
    this.looping = true,
    this.showControls = true,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController = controller;

      // Initialize video with error handling
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Video initialization timed out'),
      );

      if (!mounted) return;

      // Get video size for aspect ratio
      final size = await MediaService.getVideoSize(widget.url);
      final aspectRatio = size.width / size.height;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: aspectRatio,
        errorBuilder: (context, errorMessage) {
          widget.onError?.call();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                const SizedBox(height: 8),
                Text(
                  'Error playing video\n$errorMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400]),
                ),
              ],
            ),
          );
        },
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
      widget.onError?.call();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SizedBox(
        height: widget.maxHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 8),
              const Text(
                'Error loading video',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return SizedBox(
        height: widget.maxHeight,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: widget.maxHeight,
          child: Chewie(controller: _chewieController!),
        );
      },
    );
  }
}