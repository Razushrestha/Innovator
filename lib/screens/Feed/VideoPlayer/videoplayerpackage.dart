import 'package:innovator/screens/Feed/Inner_Homepage.dart';

class VideoPlaybackManager {
  static final VideoPlaybackManager _instance = VideoPlaybackManager._internal();
  factory VideoPlaybackManager() => _instance;
  VideoPlaybackManager._internal();

  AutoPlayVideoWidgetState? _currentPlayingVideo;

  void registerVideo(AutoPlayVideoWidgetState video) {
    if (_currentPlayingVideo != null && _currentPlayingVideo != video) {
      _currentPlayingVideo?.pauseAndMute();
    }
    _currentPlayingVideo = video;
  }

  void unregisterVideo(AutoPlayVideoWidgetState video) {
    if (_currentPlayingVideo == video) {
      _currentPlayingVideo = null;
    }
  }
}