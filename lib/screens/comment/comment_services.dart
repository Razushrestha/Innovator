import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class CommentService {
  static const String _baseUrl = 'http://182.93.94.210:3066/api/v1';

  Future<Map<String, dynamic>> addComment({
    required String contentId,
    required String commentText,
  }) async {
    final authToken = AppData().authToken;
    if (authToken == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/add-comment/$contentId'),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'type': 'content',
        'uid': contentId,
        'comment': commentText,
        'edited': false,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getComments(String contentId, {int page = 0}) async {
    final authToken = AppData().authToken;
    if (authToken == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/get-comments/$page?uid=$contentId'),
      headers: {
        'authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to get comments: ${response.statusCode}');
    }
  }

  Future<bool> updateComment({
    required String commentId,
    required String newComment,
  }) async {
    final authToken = AppData().authToken;
    if (authToken == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/update-comment/$commentId'),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'comment': newComment,
        'edited': true,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to update comment: ${response.statusCode}');
    }
  }

  Future<bool> deleteComment(String commentId) async {
    final authToken = AppData().authToken;
    if (authToken == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('$_baseUrl/delete-comment/$commentId'),
      headers: {
        'authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete comment: ${response.statusCode}');
    }
  }
}