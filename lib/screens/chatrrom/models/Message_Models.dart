class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? roomId;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.roomId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'],
      senderId: json['senderId'],
      content: json['content'] ?? json['message'],
      timestamp: DateTime.parse(json['timestamp'] ?? json['createdAt']),
      roomId: json['roomId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'roomId': roomId,
    };
  }
}