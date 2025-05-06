import 'package:video_player/video_player.dart';

class VideoPlayerManager {
  final Map<String, VideoPlayerController> _controllers = {};
  String? _currentlyPlayingId;

  void initializeController(String contentId, String videoUrl) async {
    if (_controllers.containsKey(contentId)) return;

    final controller = VideoPlayerController.network(videoUrl);
    _controllers[contentId] = controller;
    await controller.initialize();
  }

  void playVideo(String contentId) {
    if (_currentlyPlayingId == contentId) return;
    
    pauseCurrentVideo();
    
    final controller = _controllers[contentId];
    if (controller != null) {
      controller.play();
      _currentlyPlayingId = contentId;
    }
  }

  void pauseCurrentVideo() {
    if (_currentlyPlayingId != null) {
      _controllers[_currentlyPlayingId]?.pause();
      _currentlyPlayingId = null;
    }
  }

  void disposeController(String contentId) {
    _controllers[contentId]?.dispose();
    _controllers.remove(contentId);
    if (_currentlyPlayingId == contentId) {
      _currentlyPlayingId = null;
    }
  }

  void disposeAll() {
    _controllers.values.forEach((controller) => controller.dispose());
    _controllers.clear();
    _currentlyPlayingId = null;
  }
}