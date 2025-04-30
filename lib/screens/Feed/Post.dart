
class Post {
  final String id;
  final String name;
  final String position;
  final String description;
  final String imageUrl;
  final int likes;
  final int comments;
  final int shares;
  bool isLiked = false;

  Post({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}