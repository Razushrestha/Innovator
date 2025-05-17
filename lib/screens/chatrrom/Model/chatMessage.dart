class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPicture;
  final String senderEmail;
  final String receiverId;
  final String receiverName;
  final String receiverPicture;
  final String receiverEmail;
  final String content;
  final DateTime timestamp;
  final bool read;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPicture,
    required this.senderEmail,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPicture,
    required this.receiverEmail,
    required this.content,
    required this.timestamp,
    required this.read,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      senderId: json['sender']?['_id']?.toString() ?? '',
      senderName: json['sender']?['name']?.toString() ?? 'Unknown',
      senderPicture: json['sender']?['picture']?.toString() ?? '',
      senderEmail: json['sender']?['email']?.toString() ?? '',
      receiverId: json['receiver']?['_id']?.toString() ?? '',
      receiverName: json['receiver']?['name']?.toString() ?? 'Unknown',
      receiverPicture: json['receiver']?['picture']?.toString() ?? '',
      receiverEmail: json['receiver']?['email']?.toString() ?? '',
      content: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      read: json['read'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': {
        '_id': senderId,
        'name': senderName,
        'picture': senderPicture,
        'email': senderEmail,
      },
      'receiver': {
        '_id': receiverId,
        'name': receiverName,
        'picture': receiverPicture,
        'email': receiverEmail,
      },
      'message': content,
      'read': read,
      'readAt': readAt?.toIso8601String(),
      'createdAt': timestamp.toIso8601String(),
    };
  }
}