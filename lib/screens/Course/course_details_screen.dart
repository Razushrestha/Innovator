import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/screens/Course/Notes_Tab.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:video_player/video_player.dart';

import 'dart:math' as math;
import 'dart:developer' as developer;

// Enhanced Custom Video Progress Bar
class CustomVideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Color playedColor;
  final Color bufferedColor;
  final Color backgroundColor;
  final Color handleColor;
  final double barHeight;
  final double handleRadius;
  final bool allowScrubbing;

  const CustomVideoProgressBar({
    Key? key,
    required this.controller,
    this.onSeekStart,
    this.onSeekEnd,
    this.playedColor = const Color.fromRGBO(244, 135, 6, 1),
    this.bufferedColor = Colors.grey,
    this.backgroundColor = Colors.white24,
    this.handleColor = Colors.white,
    this.barHeight = 4.0,
    this.handleRadius = 8.0,
    this.allowScrubbing = true,
  }) : super(key: key);

  @override
  State<CustomVideoProgressBar> createState() => _CustomVideoProgressBarState();
}

class _CustomVideoProgressBarState extends State<CustomVideoProgressBar>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isHovering = false;
  double? _dragValue;
  late AnimationController _animationController;
  late Animation<double> _handleAnimation;
  late Animation<double> _barAnimation;
  
  // Add these for proper progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _progressTimer;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVideoListener();
    _startProgressTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _handleAnimation = Tween<double>(
      begin: widget.handleRadius,
      end: widget.handleRadius * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _barAnimation = Tween<double>(
      begin: widget.barHeight,
      end: widget.barHeight * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupVideoListener() {
    widget.controller.addListener(_updateVideoState);
    
    // Get initial values if video is already initialized
    if (widget.controller.value.isInitialized) {
      _totalDuration = widget.controller.value.duration;
      _currentPosition = widget.controller.value.position;
    }
  }

  void _startProgressTimer() {
    // Timer to update progress every 100ms for smooth updates
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && widget.controller.value.isInitialized && !_isDragging) {
        _updateVideoState();
      }
    });
  }

  void _updateVideoState() {
    if (mounted && widget.controller.value.isInitialized) {
      final newPosition = widget.controller.value.position;
      final newDuration = widget.controller.value.duration;
      
      // Only update if there's a meaningful change
      if ((newPosition - _currentPosition).abs() > const Duration(milliseconds: 100) ||
          newDuration != _totalDuration) {
        setState(() {
          _currentPosition = newPosition;
          _totalDuration = newDuration;
        });
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    widget.controller.removeListener(_updateVideoState);
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, double width) {
    if (!widget.allowScrubbing) return;
    
    _wasPlaying = widget.controller.value.isPlaying;
    
    setState(() {
      _isDragging = true;
    });
    
    _animationController.forward();
    widget.onSeekStart?.call();
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (!widget.allowScrubbing || !_isDragging) return;
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.allowScrubbing) return;
    
    setState(() {
      _isDragging = false;
      _dragValue = null;
    });
    
    _animationController.reverse();
    widget.onSeekEnd?.call();
    
    // Resume playing if it was playing before
    if (_wasPlaying) {
      widget.controller.play();
    }
  }

  void _seekToPosition(double position) {
    if (_totalDuration == Duration.zero) return;

    final newPosition = _totalDuration * position;
    setState(() {
      _dragValue = position;
      _currentPosition = newPosition; // Update immediately for responsive UI
    });
    
    widget.controller.seekTo(newPosition);
  }

  double _getProgressValue() {
    if (_isDragging && _dragValue != null) {
      return _dragValue!;
    }
    
    if (_totalDuration == Duration.zero) return 0.0;
    return (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  double _getBufferedValue() {
    final buffered = widget.controller.value.buffered;
    
    if (_totalDuration == Duration.zero || buffered.isEmpty) return 0.0;
    
    final bufferedEnd = buffered.last.end;
    return (bufferedEnd.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
        _animationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
        if (!_isDragging) {
          _animationController.reverse();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            SizedBox(
              height: 30,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final progressValue = _getProgressValue();
                  final bufferedValue = _getBufferedValue();

                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, width),
                    onPanUpdate: (details) => _onPanUpdate(details, width),
                    onPanEnd: _onPanEnd,
                    onTapDown: widget.allowScrubbing
                        ? (details) {
                            final position = details.localPosition.dx / width;
                            _seekToPosition(position.clamp(0.0, 1.0));
                          }
                        : null,
                    child: Container(
                      width: width,
                      height: 30,
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _barAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Background bar
                                Container(
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    color: widget.backgroundColor,
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                  ),
                                ),
                                // Buffered bar
                                FractionallySizedBox(
                                  widthFactor: bufferedValue,
                                  child: Container(
                                    height: _barAnimation.value,
                                    decoration: BoxDecoration(
                                      color: widget.bufferedColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    ),
                                  ),
                                ),
                                // Played bar
                                AnimatedContainer(
                                  duration: _isDragging 
                                      ? Duration.zero 
                                      : const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                  width: width * progressValue,
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.playedColor,
                                        widget.playedColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    boxShadow: _isDragging || _isHovering
                                        ? [
                                            BoxShadow(
                                              color: widget.playedColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                // Handle
                                if (_isDragging || _isHovering || widget.allowScrubbing)
                                  Positioned(
                                    left: (width * progressValue) - widget.handleRadius,
                                    top: (_barAnimation.value - (widget.handleRadius * 2)) / 2,
                                    child: AnimatedBuilder(
                                      animation: _handleAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: _handleAnimation.value * 2,
                                          height: _handleAnimation.value * 2,
                                          decoration: BoxDecoration(
                                            color: widget.handleColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.playedColor,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Time display - Fixed to show current values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isFullScreen = false;
  bool _isRotated = false;
  bool _showControls = true;
  bool _isPlaying = false;

  List<Lesson> _lessons = [];
  List<Note> _notes = [];
  List<Video> _videos = [];
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeVideoPlayer();
    _loadCourseContent();
  }

  void _initializeVideoPlayer() {
    if (widget.course.overviewVideo != null && widget.course.overviewVideo!.isNotEmpty) {
      final videoUrl = ApiService.getFullMediaUrl(widget.course.overviewVideo!);
      _videoPlayerController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          developer.log('Video initialized successfully');
        }).catchError((error) {
          developer.log('Video initialization failed: $error');
        });

      _videoPlayerController!.addListener(() {
        setState(() {
          _isPlaying = _videoPlayerController!.value.isPlaying;
        });
      });
    } else if (widget.course.videos.isNotEmpty) {
      // Use first video if no overview video
      final videoUrl = ApiService.getFullMediaUrl(widget.course.videos.first.videoUrl);
      _videoPlayerController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        });

      _videoPlayerController!.addListener(() {
        setState(() {
          _isPlaying = _videoPlayerController!.value.isPlaying;
        });
      });
    }
  }

  Future<void> _loadCourseContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final response = await ApiService.getCourseLessons(widget.course.id);
      if (response['status'] == 200) {
        setState(() {
          _lessons = widget.course.lessons;
          _notes = widget.course.notes;
          _videos = widget.course.videos;
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      developer.log('Error loading course content: $e');
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null) return;
    
    if (_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    } else {
      _videoPlayerController!.play();
    }
  }

  void _fastForward() {
    if (_videoPlayerController == null) return;
    
    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final duration = _videoPlayerController!.value.duration;
    
    if (newPosition < duration) {
      _videoPlayerController!.seekTo(newPosition);
    }
  }

  void _rewind() {
    if (_videoPlayerController == null) return;
    
    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    
    if (newPosition > Duration.zero) {
      _videoPlayerController!.seekTo(newPosition);
    } else {
      _videoPlayerController!.seekTo(Duration.zero);
    }
  }

  void _toggleRotation() {
    setState(() {
      _isRotated = !_isRotated;
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      // Hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _tabController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenVideoPlayer();
    }

    return Scaffold(
      appBar: AppBar(
       title:  Text(
          widget.course.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),

      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
        //  _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildVideoPlayer(),
                _buildCourseInfo(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      pinned: true,
      expandedHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
     actions: [
     
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Implement share functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () {
            // Implement bookmark functionality
          },
        ),
     ],
      // flexibleSpace: FlexibleSpaceBar(
      //   title: 
      // ),
    );
  }

  Widget _buildVideoPlayer() {
  return Container(
    width: double.infinity,
    color: Colors.black,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: _isVideoInitialized
          ? GestureDetector(
              onTap: _toggleControlsVisibility,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Center the video content
                    Center(
                      child: Transform.rotate(
                        angle: _isRotated ? math.pi / 2 : 0,
                        child: AspectRatio(
                          aspectRatio: _isRotated
                              ? 1 / _videoPlayerController!.value.aspectRatio
                              : _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      ),
                    ),
                    if (_showControls) _buildVideoControls(),
                  ],
                ),
              ),
            )
          : Container(
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(244, 135, 6, 1),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

 Widget _buildVideoControls() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.3),
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(0.7),
        ],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top controls
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Row(
                children: [
                  _buildControlButton(Icons.screen_rotation, _toggleRotation),
                  const SizedBox(width: 8),
                  _buildControlButton(Icons.fullscreen, _toggleFullScreen),
                ],
              ),
            ],
          ),
        ),
        // Center play button
        Flexible(
          child: Center(
            child: _buildPlayButton(),
          ),
        ),
        // Bottom controls with enhanced progress bar
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomVideoProgressBar(
              controller: _videoPlayerController!,
              onSeekStart: () {
                // Don't pause automatically - let the progress bar handle it
              },
              onSeekEnd: () {
                // Don't resume automatically - let the progress bar handle it
              },
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {double size = 24}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildPlayButton({double size = 50}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromRGBO(244, 135, 6, 1),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: size,
        ),
        onPressed: _togglePlayPause,
        padding:  EdgeInsets.all(3),
      ),
    );
  }

  Widget _buildFullScreenVideoPlayer() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Center the video in fullscreen too
              Center(
                child: Transform.rotate(
                  angle: _isRotated ? math.pi / 2 : 0,
                  child: AspectRatio(
                    aspectRatio: _isRotated
                        ? 1 / _videoPlayerController!.value.aspectRatio
                        : _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
              ),
              if (_showControls) _buildFullScreenControls(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFullScreenControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildControlButton(Icons.fullscreen_exit, _toggleFullScreen),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildControlButton(Icons.screen_rotation, _toggleRotation),
              ],
            ),
          ),
          _buildPlayButton(size: 60),
          // Center play button
          // Center(
          //   child: _buildPlayButton(size: 60),
          // ),
          // Bottom controls with enhanced progress bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomVideoProgressBar(
                  controller: _videoPlayerController!,
                  barHeight: 6.0,
                  handleRadius: 12.0,
                  onSeekStart: () {
                    if (_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.pause();
                    }
                  },
                  onSeekEnd: () {
                    if (!_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.play();
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(Icons.replay_10, _rewind, size: 32),
                    const SizedBox(width: 32),
                    _buildPlayButton(size: 40),
                    const SizedBox(width: 32),
                    _buildControlButton(Icons.forward_10, _fastForward, size: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of your existing methods remain the same...
  // (Copy all the other methods from your original file: _buildCourseInfo, _buildTabBar, etc.)

  Widget _buildCourseInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Created by ${widget.course.instructor.name}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Rating and students row - made responsive
          LayoutBuilder(
            builder: (context, constraints) {
              // If width is too small, stack vertically
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRatingSection(),
                    const SizedBox(height: 8),
                    _buildStudentsSection(),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildRatingSection()),
                    const SizedBox(width: 20),
                    _buildStudentsSection(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
          // Info chips - made responsive
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('${widget.course.contentStructure.totalLessons} lessons', Icons.play_lesson),
                  _buildInfoChip('${widget.course.contentStructure.totalVideos} videos', Icons.videocam),
                  _buildInfoChip(widget.course.level, Icons.signal_cellular_alt),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          widget.course.rating.average.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '(${widget.course.rating.count} ratings)',
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.people, color: Colors.grey, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${widget.course.enrollmentCount} students',
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(235, 111, 70, 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color.fromRGBO(244, 135, 6, 1),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(244, 135, 6, 1),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color.fromRGBO(244, 135, 6, 1),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
        tabs: [
          Tab(text: 'Playlist (${_lessons.length})'),
          Tab(text: 'Notes (${_notes.length})'),
          const Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaylistTab(),
          NotesTab(
            courseId: widget.course.id, 
            notes: widget.course.notes,
          ),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildPlaylistTab() {
    if (_isLoadingContent) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color.fromRGBO(244, 135, 6, 1),
          ),
        ),
      );
    }

    if (_lessons.isEmpty) {
      return const Center(
        child: Text(
          'No lessons available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return _buildLessonItem(lesson, index);
      },
    );
  }

  Widget _buildLessonItem(Lesson lesson, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: lesson.isPublished
                  ? const Color.fromRGBO(235, 111, 70, 0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              lesson.isPublished ? Icons.play_arrow : Icons.lock,
              color: lesson.isPublished
                  ? const Color.fromRGBO(244, 135, 6, 1)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (lesson.metadata.difficulty.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor(lesson.metadata.difficulty),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lesson.metadata.difficulty.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this course',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.course.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Instructor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: Text(
                  widget.course.instructor.name.isNotEmpty
                      ? widget.course.instructor.name[0].toUpperCase()
                      : 'I',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.instructor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.instructor.bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Course Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Language', widget.course.language),
          _buildDetailRow('Level', widget.course.level),
          _buildDetailRow('Total Lessons', '${widget.course.contentStructure.totalLessons}'),
          _buildDetailRow('Total Videos', '${widget.course.contentStructure.totalVideos}'),
          _buildDetailRow('Total Notes', '${widget.course.contentStructure.totalNotes}'),
          if (widget.course.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.course.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(235, 111, 70, 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color.fromRGBO(244, 135, 6, 1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout for bottom bar
          if (constraints.maxWidth < 350) {
            // Stack vertically on small screens
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${widget.course.price.usd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(244, 135, 6, 1),
                          ),
                        ),
                        Text(
                          'NPR ${widget.course.price.npr.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Enroll button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enrollment feature coming soon!'),
                          backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Enroll Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Horizontal layout for larger screens
            return Row(
              children: [
                // Price section
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${widget.course.price.usd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(244, 135, 6, 1),
                      ),
                    ),
                    Text(
                      'NPR ${widget.course.price.npr.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Enroll button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enrollment feature coming soon!'),
                          backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ), 
                    ),
                    child: const Text(
                      'Enroll Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}