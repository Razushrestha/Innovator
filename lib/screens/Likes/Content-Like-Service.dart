import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class ContentLikeService {
  // Base URL for the API
  final String baseUrl;
  final AppData _appData = AppData();
  
  // Constructor
  ContentLikeService({required this.baseUrl});

  /// Toggles like status for a piece of content
  /// 
  /// [contentId] The unique identifier for the content
  /// [isLiking] True if liking the content, false if unliking
  /// 
  /// Returns a Future<bool> that resolves to true if successful, false otherwise
  Future<bool> toggleLike(String contentId, bool isLiking) async {
    try {
      // Use the appropriate endpoint based on the action
      final endpoint = '/api/v1/handle-like';
      
      // Get auth token from AppData
      final authToken = _appData.authToken;
      if (authToken == null || authToken.isEmpty) {
        log('Authentication token not available');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode([
          {
            'type': 'content',
            'uid': contentId,
            'action': isLiking ? 'like' : 'unlike',
          }
        ]),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        log('Like toggle successful: $responseData');
        return true;
      } else {
        log('Failed to toggle like status. Status code: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error toggling like status: $e');
      return false;
    }
  }

  /// Likes a piece of content
  /// 
  /// [contentId] The unique identifier for the content
  /// 
  /// Returns a Future<bool> that resolves to true if successful, false otherwise
  Future<bool> likeContent(String contentId) async {
    return await toggleLike(contentId, true);
  }

  /// Unlikes a piece of content
  /// 
  /// [contentId] The unique identifier for the content
  /// 
  /// Returns a Future<bool> that resolves to true if successful, false otherwise
  Future<bool> unlikeContent(String contentId) async {
    return await toggleLike(contentId, false);
  }
}