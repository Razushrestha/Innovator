import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class CommentService {
  static const String _baseUrl = 'http://182.93.94.210:3064/api/v1';

  // Add a new comment
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

  // Get comments for content
  // Update the getComments method in CommentService
Future<List<dynamic>> getComments(String contentId, {int page = 0}) async {
  final authToken = AppData().authToken;
  if (authToken == null) throw Exception('User not authenticated');

  print('Fetching comments for content: $contentId, page: $page');
  
  final response = await http.get(
    Uri.parse('$_baseUrl/get-comments/$page?uid=$contentId'),
    headers: {
      'Authorization': 'Bearer $authToken',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Successfully fetched comments: ${data['data']?.length ?? 0}');
    return data['data'] ?? [];
  } else {
    print('Failed to get comments: ${response.statusCode}');
    throw Exception('Failed to get comments: ${response.statusCode}');
  }
}
  // Update a comment
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

    return response.statusCode == 200;
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    final authToken = AppData().authToken;
    if (authToken == null) throw Exception('User not authenticated');

    final response = await http.delete(
      Uri.parse('$_baseUrl/delete-comment/$commentId'),
      headers: {
        'authorization': 'Bearer $authToken',
      },
    );

    return response.statusCode == 200;
  }
}