import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/chatrrom/models/Message_Models.dart';
import 'package:innovator/screens/chatrrom/models/chat_room_model.dart';

class ApiService {
  static const String _baseUrl = 'http://182.93.94.210:3064/';

  Future<Map<String, String>> _getHeaders() async {
    final token = AppData().authToken;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat-rooms'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((room) => ChatRoom.fromJson(room)).toList();
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      print('Error getting chat rooms: $e');
      rethrow;
    }
  }

  Future<List<Message>> getMessages(String roomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat-rooms/$roomId/messages'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((msg) => Message.fromJson(msg)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<ChatRoom> createChatRoom(List<String> participantIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/chat-rooms'),
        headers: headers,
        body: jsonEncode({'participants': participantIds}),
      );

      if (response.statusCode == 201) {
        return ChatRoom.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create chat room');
      }
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }
}