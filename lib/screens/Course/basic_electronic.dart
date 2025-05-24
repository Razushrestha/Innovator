import 'package:flutter/material.dart';
import 'package:innovator/screens/Course/home.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({Key? key}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isFullScreen = false;
  bool _isRotated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    // Initialize with the asset video
    _videoPlayerController = VideoPlayerController.asset('assets/resistor.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      });

    // Add listener to update UI when video state changes
    _videoPlayerController!.addListener(() {
      setState(() {});
    });
  }

  void _togglePlayPause() {
    if (_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    } else {
      _videoPlayerController!.play();
    }
  }

  void _fastForward() {
    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _videoPlayerController!.seekTo(newPosition);
  }

  void _rewind() {
    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _videoPlayerController!.seekTo(newPosition);
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _tabController.dispose();
    // Ensure we reset orientation and system UI when disposing
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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
        ),
        title: const Text('Flutter', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Course header section with video player
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video player with controls
                _buildVideoPlayer(),
                const SizedBox(height: 16),
                // Course title and details
                const Text(
                  'Flutter Novice to Ninja',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Created by DevWheels',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                // Course stats
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const Text(
                      ' 4.8',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const Text(
                      ' 72 hours',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              tabs: const [
                Tab(text: 'Playlist (22)'),
                Tab(text: 'Description'),
              ],
            ),
          ),
          // Tab bar view content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Playlist tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildLessonItem(
                      title: 'Why Flutter Development',
                      isCompleted: true,
                      duration: '',
                    ),
                    _buildLessonItem(
                      title: 'Setup Flutter on MacOS',
                      isCompleted: false,
                      duration: '15 min 11 sec',
                    ),
                    _buildLessonItem(
                      title: 'Setup Flutter on Windows',
                      isCompleted: false,
                      duration: '18 min',
                    ),
                    _buildLessonItem(
                      title: 'Introduction to Flutter',
                      isCompleted: false,
                      duration: '22 min',
                    ),
                    _buildLessonItem(
                      title: 'Flutter Widgets Basics',
                      isCompleted: false,
                      duration: '32 min',
                    ),
                    _buildLessonItem(
                      title: 'Stateless vs Stateful Widgets',
                      isCompleted: false,
                      duration: '28 min 45 sec',
                    ),
                    _buildLessonItem(
                      title: 'Navigation and Routing',
                      isCompleted: false,
                      duration: '41 min',
                    ),
                    _buildLessonItem(
                      title: 'Working with Forms',
                      isCompleted: false,
                      duration: '37 min 20 sec',
                    ),
                    _buildLessonItem(
                      title: 'Theming Your App',
                      isCompleted: false,
                      duration: '25 min',
                    ),
                    _buildLessonItem(
                      title: 'State Management - Provider',
                      isCompleted: false,
                      duration: '55 min',
                    ),
                    _buildLessonItem(
                      title: 'Handling API Requests',
                      isCompleted: false,
                      duration: '48 min 30 sec',
                    ),
                    _buildLessonItem(
                      title: 'Local Storage Implementation',
                      isCompleted: false,
                      duration: '36 min',
                    ),
                    _buildLessonItem(
                      title: 'Firebase Authentication',
                      isCompleted: false,
                      duration: '52 min',
                    ),
                    _buildLessonItem(
                      title: 'Firebase Firestore',
                      isCompleted: false,
                      duration: '58 min 15 sec',
                    ),
                  ],
                ),
                // Description tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Master Flutter from the ground up! This comprehensive course takes you from absolute beginner to confident Flutter developer. You\'ll learn to build beautiful, responsive, and professional-grade mobile applications for both iOS and Android from a single codebase.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'What you\'ll learn:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Dart programming fundamentals'),
                      const Text('• Flutter UI development with widgets'),
                      const Text('• State management techniques'),
                      const Text('• Firebase integration'),
                      const Text('• Publishing to app stores'),
                      const SizedBox(height: 24),
                      const Text(
                        'Course requirements:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Basic programming knowledge in any language',
                      ),
                      const Text('• Mac, Windows, or Linux computer'),
                      const Text(
                        '• No prior Flutter or Dart experience required',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Target audience:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Complete beginners to Flutter development'),
                      const Text(
                        '• Mobile developers looking to expand their skills',
                      ),
                      const Text(
                        '• Web developers interested in mobile app development',
                      ),
                      const Text(
                        '• Students and professionals wanting to build cross-platform apps',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Instructor:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dev Wheels',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Senior Flutter Developer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Developer with over 5 years of experience in Flutter and mobile application development. Passionate about teaching and sharing knowledge with the developer community.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Video player with rotation
            Transform.rotate(
              angle: _isRotated ? math.pi / 2 : 0,
              child: AspectRatio(
                aspectRatio:
                    _isRotated
                        ? 1 / _videoPlayerController!.value.aspectRatio
                        : _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),

            // Video controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _videoPlayerController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    colors: const VideoProgressColors(
                      playedColor: Colors.purple,
                      bufferedColor: Color.fromARGB(255, 156, 39, 176),
                      backgroundColor: Colors.grey,
                    ),
                  ),

                  // Time and controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Current position / total duration
                      Text(
                        '${_formatDuration(_videoPlayerController!.value.position)} / ${_formatDuration(_videoPlayerController!.value.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),

                      // Control buttons
                      Row(
                        children: [
                          // Rewind button
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                            ),
                            onPressed: _rewind,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),

                          // Play/Pause button
                          IconButton(
                            icon: Icon(
                              _videoPlayerController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                            iconSize: 32,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),

                          // Forward button
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                            ),
                            onPressed: _fastForward,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),

                          // Rotate button
                          IconButton(
                            icon: const Icon(
                              Icons.screen_rotation,
                              color: Colors.white,
                            ),
                            onPressed: _toggleRotation,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),

                          // Fullscreen button
                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFullScreen,
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenVideoPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Centered video
            Center(
              child: Transform.rotate(
                angle: _isRotated ? math.pi / 2 : 0,
                child: AspectRatio(
                  aspectRatio:
                      _isRotated
                          ? 1 / _videoPlayerController!.value.aspectRatio
                          : _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              ),
            ),

            // Controls overlay - appears on tap
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  children: [
                    // Progress bar
                    VideoProgressIndicator(
                      _videoPlayerController!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      colors: const VideoProgressColors(
                        playedColor: Colors.purple,
                        bufferedColor: Color.fromARGB(255, 156, 39, 176),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time indicator
                        Text(
                          '${_formatDuration(_videoPlayerController!.value.position)} / ${_formatDuration(_videoPlayerController!.value.duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),

                        // Control buttons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10,
                                color: Colors.white,
                              ),
                              onPressed: _rewind,
                            ),
                            IconButton(
                              icon: Icon(
                                _videoPlayerController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                color: Colors.white,
                              ),
                              onPressed: _fastForward,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.screen_rotation,
                                color: Colors.white,
                              ),
                              onPressed: _toggleRotation,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen_exit,
                                color: Colors.white,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem({
    required String title,
    required bool isCompleted,
    required String duration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color:
                  isCompleted ? Colors.green : Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.play_arrow,
              color: isCompleted ? Colors.white : Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (duration.isNotEmpty)
                  Text(
                    duration,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
