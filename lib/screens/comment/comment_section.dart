import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/comment/comment_Model.dart';
import 'package:innovator/screens/comment/comment_services.dart';

class CommentSection extends StatefulWidget {
  final String contentId;
  final VoidCallback? onCommentAdded;

  const CommentSection({
    Key? key,
    required this.contentId,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  _CommentSectionState createState() => _CommentSectionState();
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

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_scrollListener);
    print('Initialized comment section for content: ${widget.contentId}');
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
    print('Loading initial comments for content: ${widget.contentId}');
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.getComments(widget.contentId);
      print('Successfully loaded ${comments.length} comments');
      setState(() {
        _comments = comments.map((c) => Comment.fromJson(c)).toList();
        _isLoading = false;
        _currentPage = 1;
        _hasMore = comments.length >= 10; // Assuming 10 comments per page
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments: $e')),
      );
    }
  }

  Future<void> _loadMoreComments() async {
    if (!_hasMore) return;
    print('Loading more comments, page $_currentPage');
    setState(() => _isLoading = true);
    try {
      final comments =
          await _commentService.getComments(widget.contentId, page: _currentPage);
      print('Successfully loaded ${comments.length} more comments');
      setState(() {
        _comments.addAll(comments.map((c) => Comment.fromJson(c)));
        _isLoading = false;
        _currentPage++;
        _hasMore = comments.length >= 10; // Assuming 10 comments per page
      });
    } catch (e) {
      print('Error loading more comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    print('Submitting comment: $commentText');
    setState(() => _isLoading = true);
    try {
      if (_editingCommentId != null) {
        await _commentService.updateComment(
          commentId: _editingCommentId!,
          newComment: commentText,
        );
        print('Comment updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment updated successfully!')),
        );
      } else {
        await _commentService.addComment(
          contentId: widget.contentId,
          commentText: commentText,
        );
        print('Comment added successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully!')),
        );
        widget.onCommentAdded?.call();
      }
      _commentController.clear();
      _editingCommentId = null;
      await _loadComments(); // Refresh comments
    } catch (e) {
      print('Error submitting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    print('Deleting comment: $commentId');
    setState(() => _isLoading = true);
    try {
      await _commentService.deleteComment(commentId);
      print('Comment deleted successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully!')),
      );
      await _loadComments(); // Refresh comments
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete comment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startEditingComment(Comment comment) {
    print('Starting to edit comment: ${comment.id}');
    _commentController.text = comment.comment;
    _editingCommentId = comment.id;
    FocusScope.of(context).requestFocus(FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCommentDialog();
    });
  }

  void _showCommentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: _editingCommentId != null
                      ? 'Edit your comment...'
                      : 'Write a comment...',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoading ? null : _submitComment,
                  ),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _commentController.clear();
      _editingCommentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comment input field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _submitComment,
                    ),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
            ],
          ),
        ),
        
        // Comments list
        Container(
          constraints: BoxConstraints(maxHeight: 300,
    minWidth: MediaQuery.of(context).size.width, ),// Add this),),
          child: _isLoading && _comments.isEmpty
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
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
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
    final isCurrentUser = widget.contentId == AppData().authToken?.split('|').first;
    
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            comment.comment,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimeAgo(comment.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: isCurrentUser
          ? PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 16),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _startEditingComment(comment);
                } else if (value == 'delete') {
                  _deleteComment(comment.id);
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