import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class FollowService {
  static const String _baseUrl = 'http://182.93.94.210:3064/api/v1';
  static const String _checkUrl = 'http://182.93.94.210:3064/api/v1/check';

  static Future<Map<String, dynamic>> sendFollowRequest(String email) async {
    try {
      final authToken = AppData().authToken;
      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('$_baseUrl/follow');
      final headers = {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({'email': email});

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send follow request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending follow request: $e');
    }
  }

  static Future<Map<String, dynamic>> unfollowUser(String email) async {
    try {
      final authToken = AppData().authToken;
      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('$_baseUrl/follow');
      final headers = {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({
        'email': email,
        'action': 'unfollow'
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Unfollow error response: ${response.body}');
        throw Exception('Failed to unfollow user: ${response.statusCode}');
      }
    } catch (e) {
      print('Unfollow exception: $e');
      throw Exception('Error unfollowing user: $e');
    }
  }

  static Future<bool> checkFollowStatus(String email) async {
    try {
      final authToken = AppData().authToken;
      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('$_checkUrl?email=$email');
      final headers = {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $authToken',
      };

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['isFollowing'] ?? false;
      } else {
        throw Exception('Failed to check follow status: ${response.statusCode}');
      }
    } catch (e) {
      print('Check follow status exception: $e');
      throw Exception('Error checking follow status: $e');
    }
  }
}