// chatMessage.dart
/// Represents a chat message with sender, receiver, content, and read status.
class ChatMessage {
  /// Unique identifier for the message (temporary for local messages, server-assigned after sync).
  final String id;

  /// ID of the user who sent the message.
  final String senderId;

  /// Name of the sender.
  final String senderName;

  /// URL or path to the sender's profile picture.
  final String senderPicture;

  /// Email address of the sender.
  final String senderEmail;

  /// ID of the user who receives the message.
  final String receiverId;

  /// Name of the receiver.
  final String receiverName;

  /// URL or path to the receiver's profile picture.
  final String receiverPicture;

  /// Email address of the receiver.
  final String receiverEmail;

  /// The content of the message.
  final String content;

  /// Timestamp when the message was created.
  final DateTime timestamp;

  /// Whether the message has been read by the receiver.
  bool read;

  /// Timestamp when the message was marked as read, if applicable (non-final to allow updates).
  DateTime? readAt;

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

  /// Creates a ChatMessage from a JSON map, handling various field formats.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['sender']?['_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName: json['sender']?['name']?.toString() ?? json['senderName']?.toString() ?? 'Unknown',
      senderPicture: json['sender']?['picture']?.toString() ?? json['senderPicture']?.toString() ?? '',
      senderEmail: json['sender']?['email']?.toString() ?? json['senderEmail']?.toString() ?? '',
      receiverId: json['receiver']?['_id']?.toString() ?? json['receiverId']?.toString() ?? '',
      receiverName: json['receiver']?['name']?.toString() ?? json['receiverName']?.toString() ?? 'Unknown',
      receiverPicture: json['receiver']?['picture']?.toString() ?? json['receiverPicture']?.toString() ?? '',
      receiverEmail: json['receiver']?['email']?.toString() ?? json['receiverEmail']?.toString() ?? '',
      content: json['message']?.toString() ?? json['content']?.toString() ?? '',
      timestamp: _parseTimestamp(json['createdAt'] ?? json['timestamp']),
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
    );
  }

  /// Converts the ChatMessage to a JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id, // Include both for compatibility
      'sender': {
        '_id': senderId,
        'name': senderName,
        'picture': senderPicture,
        'email': senderEmail,
      },
      'senderId': senderId,
      'senderName': senderName,
      'senderPicture': senderPicture,
      'senderEmail': senderEmail,
      'receiver': {
        '_id': receiverId,
        'name': receiverName,
        'picture': receiverPicture,
        'email': receiverEmail,
      },
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPicture': receiverPicture,
      'receiverEmail': receiverEmail,
      'message': content,
      'content': content, // Include both for compatibility
      'createdAt': timestamp.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// Parses a timestamp from various formats, defaulting to now if invalid.
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}