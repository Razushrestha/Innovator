import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/screens/comment/comment_Model.dart';
import 'package:innovator/screens/comment/comment_services.dart';

class CommentSection extends StatefulWidget {
  final String contentId;
  final VoidCallback? onCommentAdded;

  const CommentSection({Key? key, required this.contentId, this.onCommentAdded})
    : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _editingCommentId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_scrollListener);
    _getCurrentUserId(); // Get current user ID on initialization
  }

  // Get current user ID using JwtHelper
  void _getCurrentUserId() {
    final authToken = AppData().authToken;
    if (authToken != null) {
      _currentUserId = JwtHelper.extractUserId(authToken);
      debugPrint('Current user ID: $_currentUserId');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.getComments(widget.contentId);
      setState(() {
        _comments = comments.map((c) => Comment.fromJson(c)).toList();
        _isLoading = false;
        _currentPage = 1;
        _hasMore = comments.length >= 10;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load comments: $e');
    }
  }

  Future<void> _loadMoreComments() async {
    if (!_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.getComments(
        widget.contentId,
        page: _currentPage,
      );
      setState(() {
        _comments.addAll(comments.map((c) => Comment.fromJson(c)));
        _isLoading = false;
        _currentPage++;
        _hasMore = comments.length >= 10;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load more comments: $e');
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_editingCommentId != null) {
        // This is an edit operation
        await _commentService.updateComment(
          commentId: _editingCommentId!,
          newComment: commentText,
        );
        // Reload comments to show the edited comment
        await _loadComments();
        widget.onCommentAdded?.call();
        _showSuccessSnackbar('Comment updated successfully!');

        // Clear edit state
        _editingCommentId = null;
        _commentController.clear();

      } else {
        // This is a new comment
        await _commentService.addComment(
          contentId: widget.contentId,
          commentText: commentText,
        );
        _showSuccessSnackbar('Comment added successfully!');
        _commentController.clear();
        await _loadComments();
        widget.onCommentAdded?.call();
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
    SoundPlayer player = SoundPlayer();
    player.playlikeSound();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _commentService.deleteComment(commentId);
      _showSuccessSnackbar('Comment deleted successfully!');
      await _loadComments();
      widget.onCommentAdded?.call();
    } catch (e) {
      _showErrorSnackbar('Failed to delete comment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditingComment(Comment comment) {
    setState(() {
      _commentController.text = comment.comment;
      _editingCommentId = comment.id;
    });
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelEditing() {
    setState(() {
      _commentController.clear();
      _editingCommentId = null;
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText:
                        _editingCommentId != null
                            ? 'Edit your comment...'
                            : 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_editingCommentId != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelEditing,
                            tooltip: 'Cancel editing',
                          ),
                        IconButton(
                          icon:
                              _editingCommentId != null
                                  ? const Icon(Icons.save)
                                  : const Icon(Icons.send),
                          onPressed: _isLoading ? null : _submitComment,
                          tooltip:
                              _editingCommentId != null
                                  ? 'Save edit'
                                  : 'Send comment',
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
            ],
          ),
        ),

        if (_editingCommentId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Editing comment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        Container(
          constraints: BoxConstraints(
            maxHeight: 300,
            minWidth: MediaQuery.of(context).size.width,
          ),
          child:
              _isLoading && _comments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _comments.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _comments.length) {
                        return _hasMore
                            ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                            : const SizedBox();
                      }

                      final comment = _comments[index];
                      return _buildCommentTile(comment);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final isCurrentUser =
        _currentUserId != null && _currentUserId == comment.user.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          'http://182.93.94.210:3064${comment.user.picture}',
        ),
        radius: 20,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(comment.comment, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatTimeAgo(comment.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (comment.edited)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '(edited)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing:
          isCurrentUser
              ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    _startEditingComment(comment);
                  } else if (value == 'delete') {
                    await _deleteComment(comment.id);
                  }
                },
              )
              : null,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
