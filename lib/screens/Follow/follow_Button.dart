import 'package:flutter/material.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';

class FollowButton extends StatefulWidget {
  final String targetUserEmail;
  final VoidCallback? onFollowSuccess;
  final VoidCallback? onUnfollowSuccess; // Add callback for unfollow
  final double? size;
  final bool initialFollowStatus;

  const FollowButton({
    Key? key,
    required this.targetUserEmail,
    this.onFollowSuccess,
    this.onUnfollowSuccess, // Add this parameter
    this.size,
    this.initialFollowStatus = false,
  }) : super(key: key);

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  int _state = 0; // 0 = plus, 1 = requested text, 2 = following (checkmark), 3 = unfollow hover
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  bool _isHovering = false; // Track hover state for unfollow

  @override
  void initState() {
    super.initState();
    // Initialize state based on initialFollowStatus
    _state = widget.initialFollowStatus ? 2 : 0;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _widthAnimation = Tween<double>(begin: 1, end: 2.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 40.0;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _handleHoverChange(true),
          onExit: (_) => _handleHoverChange(false),
          child: SizedBox(
            width: size * _widthAnimation.value,
            height: size,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size / 2),
                ),
              ),
              onPressed: _isLoading ? null : _handleButtonPress,
              child: _buildChild(size),
            ),
          ),
        );
      },
    );
  }

  Color _getButtonColor() {
    if (_state == 2 && !_isHovering) {
      return Colors.green;
    } else if (_state == 2 && _isHovering) {
      return Colors.red; // Red when hovering over "Following" button
    } else {
      return Colors.blue;
    }
  }

  void _handleHoverChange(bool isHovering) {
    if (_state == 2) {
      setState(() {
        _isHovering = isHovering;
      });
    }
  }

  Widget _buildChild(double size) {
    if (_isLoading) {
      return SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    // Show "Unfollow" text when hovering over checkmark
    if (_state == 2 && _isHovering) {
      return Text(
        'Unfollow',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    switch (_state) {
      case 0:
        return Icon(Icons.person_add, color: Colors.white, size: size * 0.6);
      case 1:
        return Text(
          'Requested',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
          ),
        );
      case 2:
        return Icon(Icons.check, color: Colors.white, size: size * 0.6);
      default:
        return Icon(Icons.person_add, color: Colors.white, size: size * 0.6);
    }
  }

  Future<void> _handleButtonPress() async {
    if (_isLoading) return;

    // If already following, unfollow
    if (_state == 2) {
      await _handleUnfollow();
    } else {
      // Otherwise, send follow request
      await _handleFollow();
    }
  }

  Future<void> _handleFollow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show "Requested" text with animation
      setState(() => _state = 1);
      await _animationController.forward();
      
      // Send follow request
      await FollowService.sendFollowRequest(widget.targetUserEmail);
      
      // Wait a moment before showing checkmark
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Show checkmark
      setState(() => _state = 2);
      await _animationController.reverse();
      
      if (widget.onFollowSuccess != null) {
        widget.onFollowSuccess!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow request sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Reset on error
      setState(() => _state = 0);
      _animationController.reset();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnfollow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Animate button width
      await _animationController.forward();
      
      // Send unfollow request
      final result = await FollowService.unfollowUser(widget.targetUserEmail);
      
      // Print response for debugging
      print('Unfollow response: $result');
      
      // Reset to "follow" state
      setState(() => _state = 0);
      await _animationController.reverse();
      
      if (widget.onUnfollowSuccess != null) {
        widget.onUnfollowSuccess!();
      } else if (widget.onFollowSuccess != null) {
        // If no specific unfollow callback, use the follow callback with false
        widget.onFollowSuccess!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unfollowed successfully'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      // Keep following state on error
      setState(() => _state = 2);
      _animationController.reset();
      
      // More descriptive error message
      String errorMessage = e.toString();
      if (errorMessage.contains('FormatException')) {
        errorMessage = 'Server returned invalid response. The unfollow endpoint might not be configured correctly.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Log the full error for debugging
      print('Unfollow error details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}