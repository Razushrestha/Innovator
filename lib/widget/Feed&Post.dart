import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedToggleButton extends StatefulWidget {
  final Function(bool isPost) onToggle;
  final bool initialValue;
  final Color? accentColor;
  final double? size;
  
  const FeedToggleButton({
    Key? key,
    required this.onToggle,
    this.initialValue = true,
    this.accentColor,
    this.size,
  }) : super(key: key);

  @override
  State<FeedToggleButton> createState() => _FeedToggleButtonState();
}

class _FeedToggleButtonState extends State<FeedToggleButton>
    with TickerProviderStateMixin {
  late bool isPostSelected;
  late AnimationController _animationController;
  late AnimationController _switchController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Color accentColor;
  late double buttonSize;

  @override
  void initState() {
    super.initState();
    isPostSelected = widget.initialValue;
    accentColor = widget.accentColor ?? Color.fromRGBO(244, 135, 6, 1);
    buttonSize = widget.size ?? 44.0; // Much smaller default size
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _switchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0.5),
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (_switchController.isAnimating) return;
    
    HapticFeedback.lightImpact();
    
    // Quick press animation
    await _animationController.forward();
    _animationController.reverse();
    
    // Switch animation
    if (isPostSelected) {
      _switchController.forward();
    } else {
      _switchController.reverse();
    }
    
    setState(() {
      isPostSelected = !isPostSelected;
    });
    
    widget.onToggle(isPostSelected);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[100];
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _switchController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: buttonSize,
              height: buttonSize * 1.8, // Compact aspect ratio
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonSize / 2),
                color: backgroundColor,
                border: Border.all(
                  color: borderColor!,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDarkMode ? 20 : 6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(isDarkMode ? 10 : 2),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    top: isPostSelected ? 2 : buttonSize * 0.9,
                    left: 2,
                    right: 2,
                    child: Container(
                      height: buttonSize * 0.75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(buttonSize / 2.5),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.8),
                          ],
                        ), 
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Icons container
                  Column(
                    children: [
                      // Post icon (top)
                      Expanded(
                        child: Transform.rotate(
                          angle: isPostSelected ? 0 : _rotationAnimation.value,
                          child: SlideTransition(
                            position: isPostSelected 
                                ? const AlwaysStoppedAnimation(Offset.zero)
                                : _slideAnimation,
                            child: Container(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_rounded,
                                    size: buttonSize * 0.32,
                                    color: isPostSelected 
                                        ? Colors.white 
                                        : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                                  ),
                                  SizedBox(height: 1),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPostSelected 
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Minimal divider
                      Container(
                        height: 0.5,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      ),
                      
                      // Video icon (bottom)
                      Expanded(
                        child: Transform.rotate(
                          angle: !isPostSelected ? 0 : -_rotationAnimation.value,
                          child: SlideTransition(
                            position: !isPostSelected 
                                ? const AlwaysStoppedAnimation(Offset.zero)
                                : _slideAnimation,
                            child: Container(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: !isPostSelected 
                                          ? Colors.white.withAlpha(80)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Icon(
                                    Icons.play_circle_rounded,
                                    size: buttonSize * 0.32,
                                    color: !isPostSelected 
                                        ? Colors.white 
                                        : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// class FeedScreen extends StatefulWidget {
//   @override
//   State<FeedScreen> createState() => _FeedScreenState();
// }

// class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
//   bool showPostFeed = true;
//   late AnimationController _contentAnimationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _contentAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 350),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _contentAnimationController,
//         curve: Curves.easeOut,
//       ),
//     );
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.05),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _contentAnimationController,
//       curve: Curves.easeOutCubic,
//     ));
    
//     _contentAnimationController.forward();
//   }

//   @override
//   void dispose() {
//     _contentAnimationController.dispose();
//     super.dispose();
//   }

//   void _onFeedToggle(bool isPost) async {
//     await _contentAnimationController.reverse();
//     setState(() {
//       showPostFeed = isPost;
//     });
//     _contentAnimationController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
//     return Scaffold(
//       backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Feed',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.3,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
//         foregroundColor: isDarkMode ? Colors.white : Colors.black87,
//         elevation: 0,
//         shadowColor: Colors.transparent,
//         systemOverlayStyle: isDarkMode 
//             ? SystemUiOverlayStyle.light 
//             : SystemUiOverlayStyle.dark,
//       ),
//       body: Stack(
//         children: [
//           // Subtle background
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: isDarkMode
//                     ? [Colors.grey[900]!, Colors.grey[850]!]
//                     : [Colors.grey[50]!, Colors.white],
//               ),
//             ),
//           ),
          
//           // Main content
//           AnimatedBuilder(
//             animation: _contentAnimationController,
//             builder: (context, child) {
//               return FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SlideTransition(
//                   position: _slideAnimation,
//                   child: Container(
//                     width: double.infinity,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // Compact icon container
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: LinearGradient(
//                               colors: showPostFeed
//                                   ? [
//                                       const Color(0xFF6C5CE7),
//                                       const Color(0xFFA29BFE),
//                                     ]
//                                   : [
//                                       const Color(0xFFE84393),
//                                       const Color(0xFFFD79A8),
//                                     ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: (showPostFeed 
//                                     ? const Color(0xFF6C5CE7) 
//                                     : const Color(0xFFE84393)).withOpacity(0.25),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                           ),
//                           child: Icon(
//                             showPostFeed ? Icons.article_rounded : Icons.play_circle_rounded,
//                             size: 36,
//                             color: Colors.white,
//                           ),
//                         ),
                        
//                         const SizedBox(height: 24),
                        
//                         // Title
//                         Text(
//                           showPostFeed ? 'Post Feed' : 'Video Feed',
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.w700,
//                             color: isDarkMode ? Colors.white : Colors.black87,
//                             letterSpacing: -0.3,
//                           ),
//                         ),
                        
//                         const SizedBox(height: 8),
                        
//                         // Subtitle
//                         Text(
//                           showPostFeed 
//                               ? 'Articles and text posts' 
//                               : 'Video content',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                             letterSpacing: 0.1,
//                           ),
//                         ),
                        
//                         const SizedBox(height: 32),
                        
//                         // Minimal status indicator
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: (showPostFeed 
//                                 ? const Color(0xFF6C5CE7) 
//                                 : const Color(0xFFE84393)).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: (showPostFeed 
//                                   ? const Color(0xFF6C5CE7) 
//                                   : const Color(0xFFE84393)).withOpacity(0.2),
//                               width: 0.5,
//                             ),
//                           ),
//                           child: Text(
//                             showPostFeed ? 'Posts Active' : 'Videos Active',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: showPostFeed 
//                                   ? const Color(0xFF6C5CE7) 
//                                   : const Color(0xFFE84393),
//                               fontWeight: FontWeight.w500,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
          
//           // Compact floating toggle button
//           Positioned(
//             right: 16,
//             top: MediaQuery.of(context).size.height * 0.4,
//             child: FeedToggleButton(
//               initialValue: showPostFeed,
//               accentColor: showPostFeed 
//                   ? const Color(0xFF6C5CE7) 
//                   : const Color(0xFFE84393),
//               size: 38, // Very compact size
//               onToggle: _onFeedToggle,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }