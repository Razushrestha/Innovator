import 'package:flutter/material.dart';

class CustomFAB extends StatefulWidget {
  final String gifAsset; // Changed from lottieAsset to gifAsset
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color splashColor;
  final double size;
  final BoxShape shape;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool showBadge;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final double gifSize; // Changed from lottieSize to gifSize
  final double badgeSize;
  final double badgeTextSize;
  final BoxBorder? border;
  final Duration animationDuration;

  const CustomFAB({
    Key? key,
    required this.gifAsset, // Changed parameter name
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.splashColor = Colors.white24,
    this.size = 56.0,
    this.shape = BoxShape.circle,
    this.margin = const EdgeInsets.all(16.0),
    this.padding = const EdgeInsets.all(8.0),
    this.elevation = 100.0,
    this.showBadge = false,
    this.badgeText = "",
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
    this.gifSize = 300.0, // Changed parameter name
    this.badgeSize = 20.0,
    this.badgeTextSize = 10.0,
    this.border,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _CustomFABState createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main FAB
              Material(
                elevation: widget.elevation,
                shape: widget.shape == BoxShape.circle
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                color: widget.backgroundColor,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    shape: widget.shape,
                    border: widget.border,
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.gifAsset,
                      width: widget.size * 2.0, // Adjust size as needed
                      height: widget.size * 2.0, // Adjust size as needed
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              
              // Badge
              if (widget.showBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: widget.badgeSize,
                    height: widget.badgeSize,
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: widget.badgeText.isNotEmpty
                          ? Text(
                              widget.badgeText,
                              style: TextStyle(
                                color: widget.badgeTextColor,
                                fontSize: widget.badgeTextSize,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example usage remains the same, just change the asset parameter name
class CountBadgeFAB extends StatelessWidget {
  final int count;
  final String gifAsset; // Changed from lottieAsset
  final VoidCallback onPressed;
  final Color backgroundColor;

  const CountBadgeFAB({
    Key? key,
    required this.count,
    required this.gifAsset, // Changed parameter name
    required this.onPressed,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFAB(
      gifAsset: gifAsset, // Changed parameter name
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      showBadge: count > 0,
      badgeText: count > 99 ? '99+' : count.toString(),
    );
  }
}

class NotificationFAB extends StatelessWidget {
  final bool hasNotification;
  final String gifAsset; // Changed from lottieAsset
  final VoidCallback onPressed;
  final Color backgroundColor;

  const NotificationFAB({
    Key? key, 
    required this.hasNotification,
    required this.gifAsset, // Changed parameter name
    required this.onPressed,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFAB(
      gifAsset: gifAsset, // Changed parameter name
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      showBadge: hasNotification,
      badgeText: '',
    );
  }
}