import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FixedCustomVideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Color playedColor;
  final Color bufferedColor;
  final Color backgroundColor;
  final Color handleColor;
  final double barHeight;
  final double handleRadius;
  final bool allowScrubbing;

  const FixedCustomVideoProgressBar({
    Key? key,
    required this.controller,
    this.onSeekStart,
    this.onSeekEnd,
    this.playedColor = const Color.fromRGBO(244, 135, 6, 1),
    this.bufferedColor = Colors.grey,
    this.backgroundColor = Colors.white24,
    this.handleColor = Colors.white,
    this.barHeight = 4.0,
    this.handleRadius = 8.0,
    this.allowScrubbing = true,
  }) : super(key: key);

  @override
  State<FixedCustomVideoProgressBar> createState() => _FixedCustomVideoProgressBarState();
}

class _FixedCustomVideoProgressBarState extends State<FixedCustomVideoProgressBar>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isHovering = false;
  double? _dragValue;
  late AnimationController _animationController;
  late Animation<double> _handleAnimation;
  late Animation<double> _barAnimation;
  
  // Add these for proper progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVideoListener();
    _startProgressTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _handleAnimation = Tween<double>(
      begin: widget.handleRadius,
      end: widget.handleRadius * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _barAnimation = Tween<double>(
      begin: widget.barHeight,
      end: widget.barHeight * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupVideoListener() {
    widget.controller.addListener(_updateVideoState);
    
    // Get initial duration if video is already initialized
    if (widget.controller.value.isInitialized) {
      _totalDuration = widget.controller.value.duration;
      _currentPosition = widget.controller.value.position;
    }
  }

  void _startProgressTimer() {
    // Timer to update progress every 100ms for smooth updates
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.controller.value.isInitialized && !_isDragging) {
        _updateVideoState();
      }
    });
  }

  void _updateVideoState() {
    if (mounted && widget.controller.value.isInitialized) {
      final newPosition = widget.controller.value.position;
      final newDuration = widget.controller.value.duration;
      
      if (newPosition != _currentPosition || newDuration != _totalDuration) {
        setState(() {
          _currentPosition = newPosition;
          _totalDuration = newDuration;
        });
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    widget.controller.removeListener(_updateVideoState);
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, double width) {
    if (!widget.allowScrubbing) return;
    
    setState(() {
      _isDragging = true;
    });
    
    _animationController.forward();
    widget.onSeekStart?.call();
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (!widget.allowScrubbing || !_isDragging) return;
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.allowScrubbing) return;
    
    setState(() {
      _isDragging = false;
      _dragValue = null;
    });
    
    _animationController.reverse();
    widget.onSeekEnd?.call();
  }

  void _seekToPosition(double position) {
    if (_totalDuration == Duration.zero) return;

    final newPosition = _totalDuration * position;
    setState(() {
      _dragValue = position;
      _currentPosition = newPosition; // Update immediately for responsive UI
    });
    
    widget.controller.seekTo(newPosition);
  }

  double _getProgressValue() {
    if (_isDragging && _dragValue != null) {
      return _dragValue!;
    }
    
    if (_totalDuration == Duration.zero) return 0.0;
    return (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  double _getBufferedValue() {
    final buffered = widget.controller.value.buffered;
    
    if (_totalDuration == Duration.zero || buffered.isEmpty) return 0.0;
    
    final bufferedEnd = buffered.last.end;
    return (bufferedEnd.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
        _animationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
        if (!_isDragging) {
          _animationController.reverse();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            SizedBox(
              height: 30,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final progressValue = _getProgressValue();
                  final bufferedValue = _getBufferedValue();

                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, width),
                    onPanUpdate: (details) => _onPanUpdate(details, width),
                    onPanEnd: _onPanEnd,
                    onTapDown: widget.allowScrubbing
                        ? (details) {
                            final position = details.localPosition.dx / width;
                            _seekToPosition(position.clamp(0.0, 1.0));
                          }
                        : null,
                    child: Container(
                      width: width,
                      height: 30,
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _barAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Background bar
                                Container(
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    color: widget.backgroundColor,
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                  ),
                                ),
                                // Buffered bar
                                FractionallySizedBox(
                                  widthFactor: bufferedValue,
                                  child: Container(
                                    height: _barAnimation.value,
                                    decoration: BoxDecoration(
                                      color: widget.bufferedColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    ),
                                  ),
                                ),
                                // Played bar
                                AnimatedContainer(
                                  duration: _isDragging 
                                      ? Duration.zero 
                                      : const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                  width: width * progressValue,
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.playedColor,
                                        widget.playedColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    boxShadow: _isDragging || _isHovering
                                        ? [
                                            BoxShadow(
                                              color: widget.playedColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                // Handle
                                if (_isDragging || _isHovering || widget.allowScrubbing)
                                  Positioned(
                                    left: (width * progressValue) - widget.handleRadius,
                                    top: (_barAnimation.value - (widget.handleRadius * 2)) / 2,
                                    child: AnimatedBuilder(
                                      animation: _handleAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: _handleAnimation.value * 2,
                                          height: _handleAnimation.value * 2,
                                          decoration: BoxDecoration(
                                            color: widget.handleColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.playedColor,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Time display - THIS IS THE FIX FOR YOUR ISSUE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}