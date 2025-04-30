class Comment {
  final String id;
  final String type;
  final String contentId;
  final CommentUser user;
  final String comment;
  final bool edited;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.type,
    required this.contentId,
    required this.user,
    required this.comment,
    required this.edited,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      contentId: json['uid'] ?? '',
      user: CommentUser.fromJson(json['user'] ?? {}),
      comment: json['comment'] ?? '',
      edited: json['edited'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class CommentUser {
  final String id;
  final String name;
  final String email;
  final String picture;

  CommentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      picture: json['picture'] ?? '',
    );
  }
}