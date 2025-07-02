import 'dart:async';
import 'package:flutter/foundation.dart';

class FollowStatusManager {
  static final FollowStatusManager _instance = FollowStatusManager._internal();
  factory FollowStatusManager() => _instance;
  FollowStatusManager._internal();

  // Stream controllers for follow status changes
  final Map<String, StreamController<bool>> _statusControllers = {};
  final Map<String, bool> _followStatusCache = {};

  // Get stream for a specific user's follow status
  Stream<bool> getFollowStatusStream(String userEmail) {
    if (!_statusControllers.containsKey(userEmail)) {
      _statusControllers[userEmail] = StreamController<bool>.broadcast();
    }
    return _statusControllers[userEmail]!.stream;
  }

  // Update follow status and notify all listeners
  void updateFollowStatus(String userEmail, bool isFollowing) {
    debugPrint('📢 FollowStatusManager: Updating status for $userEmail to $isFollowing');
    
    _followStatusCache[userEmail] = isFollowing;
    
    if (_statusControllers.containsKey(userEmail)) {
      _statusControllers[userEmail]!.add(isFollowing);
    }
  }

  // Get cached follow status
  bool? getCachedFollowStatus(String userEmail) {
    return _followStatusCache[userEmail];
  }

  // Clear cache for a user
  void clearUserCache(String userEmail) {
    _followStatusCache.remove(userEmail);
  }

  // Clear all cache
  void clearAllCache() {
    _followStatusCache.clear();
  }

  // Dispose stream controller for a user
  void disposeUserStream(String userEmail) {
    if (_statusControllers.containsKey(userEmail)) {
      _statusControllers[userEmail]!.close();
      _statusControllers.remove(userEmail);
    }
  }

  // Dispose all streams
  void dispose() {
    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _statusControllers.clear();
    _followStatusCache.clear();
  }
}