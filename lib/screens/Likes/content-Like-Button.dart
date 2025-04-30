import 'package:flutter/material.dart';
import 'package:innovator/screens/Likes/Content-Like-Service.dart';

class LikeButton extends StatefulWidget {
  final String contentId;
  final bool initialLikeStatus;
  final ContentLikeService likeService;
    final Function(bool)? onLikeToggled;  // Add this parameter


  const LikeButton({
    Key? key,
    required this.contentId,
    required this.initialLikeStatus,
    required this.likeService, this.onLikeToggled,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool isLiked;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialLikeStatus;
  }

  Future<void> _handleToggleLike() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final newLikeStatus = !isLiked;
    final success = await widget.likeService.toggleLike(widget.contentId, newLikeStatus);

    setState(() {
      if (success) {
  isLiked = newLikeStatus;
  // Call the callback if it exists
  if (widget.onLikeToggled != null) {
    widget.onLikeToggled!(isLiked);
  }
}
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : null,
      ),
      onPressed: isLoading ? null : _handleToggleLike,
    );
  }
}
