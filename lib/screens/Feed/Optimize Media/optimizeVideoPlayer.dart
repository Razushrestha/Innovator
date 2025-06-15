import 'dart:async';

import 'package:flutter/material.dart';
import 'package:innovator/screens/Feed/Services/MediaService.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class OptimizedVideoPlayer extends StatefulWidget {
  final String url;
  final double? maxHeight;
  final double? maxWidth;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final bool isMuted; // Add this parameter
  final VoidCallback? onError;

  const OptimizedVideoPlayer({
    required this.url,
    this.maxHeight,
    this.maxWidth,
    this.autoPlay = true,
    this.looping = true,
    this.showControls = true,
    this.isMuted = true,
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

      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Video initialization timed out'),
      );

      if (!mounted) return;

      final size = await MediaService.getVideoSize(widget.url);
      final aspectRatio = size.width / size.height;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: aspectRatio,
        allowMuting: true,
        startAt: Duration.zero,
        isLive: false,
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

      // Set initial volume based on isMuted
      await _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        widget.onError?.call();
      }
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
          width: widget.maxWidth,
          height: widget.maxHeight,
          child: Chewie(controller: _chewieController!),
        );
      },
    );
  }
}