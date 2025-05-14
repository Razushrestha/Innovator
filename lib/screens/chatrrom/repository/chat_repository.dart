import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'dart:developer' as developer;

// Model for Chat Room
class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final Message? lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Chat',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
    );
  }
}

// Model for Message
class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatRepository {
  static const String baseUrl = 'http://182.93.94.210:3064/api/v1';

  // Get all chat rooms for the current user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final token = AppData().authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      developer.log('Fetching chat rooms with token: ${token.length > 10 ? token.substring(0, 10) + '...' : token}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      developer.log('Chat rooms API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Parse the response body
        final responseBody = json.decode(response.body);
        
        // Debug the response structure
        developer.log('Response structure: ${responseBody.runtimeType}');
        
        List<dynamic> chatRoomsList;
        
        // Handle different response formats
        if (responseBody is Map<String, dynamic>) {
          // If it's a map, look for the data field or other fields that might contain the chat rooms
          if (responseBody.containsKey('data')) {
            chatRoomsList = responseBody['data'] as List<dynamic>;
            developer.log('Found chat rooms in "data" field: ${chatRoomsList.length}');
          } else if (responseBody.containsKey('chats')) {
            chatRoomsList = responseBody['chats'] as List<dynamic>;
            developer.log('Found chat rooms in "chats" field: ${chatRoomsList.length}');
          } else if (responseBody.containsKey('rooms')) {
            chatRoomsList = responseBody['rooms'] as List<dynamic>;
            developer.log('Found chat rooms in "rooms" field: ${chatRoomsList.length}');
          } else {
            // If no specific field is found, try to find a list in the response
            final possibleList = responseBody.values.firstWhere(
              (value) => value is List,
              orElse: () => <dynamic>[],
            );
            
            if (possibleList is List) {
              chatRoomsList = possibleList;
              developer.log('Found chat rooms in unknown field: ${chatRoomsList.length}');
            } else {
              // If we still can't find a list, log the keys and throw an error
              developer.log('Response keys: ${responseBody.keys.join(', ')}');
              throw Exception('Cannot find chat rooms list in the response');
            }
          }
        } else if (responseBody is List<dynamic>) {
          // If the response is already a list, use it directly
          chatRoomsList = responseBody;
          developer.log('Response is a list of chat rooms: ${chatRoomsList.length}');
        } else {
          // Unexpected format
          throw Exception('Unexpected response format: ${responseBody.runtimeType}');
        }
        
        // Convert each item to a ChatRoom object
        return chatRoomsList.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        developer.log('Failed to load chat rooms: ${response.body}');
        throw Exception('Failed to load chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getChatRooms: $e');
      throw Exception('Failed to fetch chat rooms: $e');
    }
  }

  // Get messages for a specific chat room
  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final token = AppData().authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      developer.log('Fetching messages for chat: $chatId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      developer.log('Messages API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        List<dynamic> messagesList;
        
        // Handle different response formats
        if (responseBody is Map<String, dynamic>) {
          if (responseBody.containsKey('data')) {
            messagesList = responseBody['data'] as List<dynamic>;
          } else if (responseBody.containsKey('messages')) {
            messagesList = responseBody['messages'] as List<dynamic>;
          } else {
            // Try to find a list in the response
            final possibleList = responseBody.values.firstWhere(
              (value) => value is List,
              orElse: () => <dynamic>[],
            );
            
            if (possibleList is List) {
              messagesList = possibleList;
            } else {
              developer.log('Response keys: ${responseBody.keys.join(', ')}');
              throw Exception('Cannot find messages list in the response');
            }
          }
        } else if (responseBody is List<dynamic>) {
          messagesList = responseBody;
        } else {
          throw Exception('Unexpected response format: ${responseBody.runtimeType}');
        }
        
        return messagesList.map((json) => Message.fromJson(json)).toList();
      } else {
        developer.log('Failed to load messages: ${response.body}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getChatMessages: $e');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send a message to a chat room
  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final token = AppData().authToken;
      final userId = AppData().currentUserId;
      
      if (token == null || userId == null) {
        throw Exception('User not authenticated');
      }
      
      developer.log('Sending message to chat: $chatId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content,
          'senderId': userId,
        }),
      );
      
      developer.log('Send message API response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        Map<String, dynamic> messageData;
        
        // Handle different response formats
        if (responseBody is Map<String, dynamic>) {
          if (responseBody.containsKey('data')) {
            messageData = responseBody['data'] as Map<String, dynamic>;
          } else if (responseBody.containsKey('message')) {
            messageData = responseBody['message'] as Map<String, dynamic>;
          } else {
            // If the response itself is the message
            messageData = responseBody;
          }
        } else {
          throw Exception('Unexpected response format: ${responseBody.runtimeType}');
        }
        
        return Message.fromJson(messageData);
      } else {
        developer.log('Failed to send message: ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in sendMessage: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Create a new chat room
  Future<ChatRoom> createChatRoom(String name, List<String> participantIds) async {
    try {
      final token = AppData().authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      developer.log('Creating chat room: $name with participants: ${participantIds.join(', ')}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'participants': participantIds,
        }),
      );
      
      developer.log('Create chat room API response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        Map<String, dynamic> chatRoomData;
        
        // Handle different response formats
        if (responseBody is Map<String, dynamic>) {
          if (responseBody.containsKey('data')) {
            chatRoomData = responseBody['data'] as Map<String, dynamic>;
          } else if (responseBody.containsKey('chatRoom')) {
            chatRoomData = responseBody['chatRoom'] as Map<String, dynamic>;
          } else if (responseBody.containsKey('room')) {
            chatRoomData = responseBody['room'] as Map<String, dynamic>;
          } else {
            // If the response itself is the chat room
            chatRoomData = responseBody;
          }
        } else {
          throw Exception('Unexpected response format: ${responseBody.runtimeType}');
        }
        
        return ChatRoom.fromJson(chatRoomData);
      } else {
        developer.log('Failed to create chat room: ${response.body}');
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in createChatRoom: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }
}