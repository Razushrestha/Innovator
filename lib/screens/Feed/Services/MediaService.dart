import 'dart:async';
import 'dart:ui';
import 'package:video_player/video_player.dart';

class MediaService {
  // Cache video sizes to avoid repeated initialization
  static final Map<String, Size> _videoSizeCache = {};
  
  // Cache video initialization states
  static final Map<String, Completer<void>> _videoInitCache = {};

  static Future<Size> getVideoSize(String url) async {
    // Check cache first
    if (_videoSizeCache.containsKey(url)) {
      return _videoSizeCache[url]!;
    }

    // Check if initialization is already in progress
    if (_videoInitCache.containsKey(url)) {
      await _videoInitCache[url]!.future;
      return _videoSizeCache[url]!;
    }

    // Create new initialization completer
    final completer = Completer<void>();
    _videoInitCache[url] = completer;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      final size = controller.value.size;
      
      // Cache the size
      _videoSizeCache[url] = size;
      
      // Cleanup
      await controller.dispose();
      completer.complete();
      _videoInitCache.remove(url);
      
      return size;
    } catch (e) {
      completer.completeError(e);
      _videoInitCache.remove(url);
      throw e;
    }
  }

  static void clearCache() {
    _videoSizeCache.clear();
    _videoInitCache.clear();
  }
}