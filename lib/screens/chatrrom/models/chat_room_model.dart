import 'package:innovator/screens/chatrrom/models/Message_Models.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final DateTime createdAt;
  final Message? lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? 'Chat Room',
      participants: List<String>.from(json['participants']),
      createdAt: DateTime.parse(json['createdAt']),
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
    );
  }
}