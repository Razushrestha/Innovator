import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Add_Content/Create_post.dart';
import 'package:innovator/screens/Course/home.dart';
import 'package:innovator/screens/Search/Searchpage.dart';
import 'package:innovator/screens/Search/Searchpage.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';
import 'package:innovator/utils/Drawer/custom_drawer.dart';
import 'package:get/get.dart';
import 'package:innovator/controllers/user_controller.dart';

class FloatingMenuWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const FloatingMenuWidget({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _FloatingMenuWidgetState createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends State<FloatingMenuWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Track the position of the menu button
  double _buttonX = 0;
  double _buttonY = 0;

  final UserController _userController = Get.find<UserController>();

  // Features to display above the menu button with their respective actions
  final List<Map<String, dynamic>> _topIcons = [
    {
      'icon': Icons.library_books,
      'name': 'Golf Course',
      'action': 'navigate_golf',
    },
    {'icon': Icons.school, 'name': 'Search', 'action': 'open_search'},
    {'icon': Icons.add_a_photo, 'name': 'Search', 'action': 'add_photo'},
  ];

  // Features to display below the menu button with their respective actions
  final List<Map<String, dynamic>> _bottomIcons = [
    {'icon': Icons.shop, 'name': 'Settings', 'action': 'open_settings'},
    {'icon': Icons.search, 'name': 'Profile', 'action': 'view_profile'},
    {'icon': Icons.menu, 'name': 'Drawer', 'action': 'drawer'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Position will be set in first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          // Default position at right middle
          _buttonX = size.width - 60;
          _buttonY = size.height * 0.5;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Handle icon press actions
  void _handleIconPress(String action, BuildContext context) {
    switch (action) {
      case 'navigate_golf':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage() ),
          
        );
        break;

      case 'open_search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderScope(child: HomeScreen()),
          ),

        );
        break;

      case 'add_photo':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CreatePostScreen()),
          
        );
        break;

      case 'open_settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopPage()),
          
        );
        break;

      case 'view_profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(),
          ),
          
        );
        break;

      case 'drawer':
        SmoothDrawerService.showLeftDrawer(context);
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented yet: $action')),
        );
    }
  }

  void _showLeftSideDrawer(BuildContext context) {
    // Drawer width calculation - typically 80% of screen width but not more than 300px
    final double drawerWidth = math.min(
      MediaQuery.of(context).size.width * 0.8,
      300.0,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Drawer",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container(); // This isn't used but required
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Scale and fade animations for smooth appearance
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return Stack(
          children: [
            // Tap outside to dismiss
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),

            // The drawer itself with animations
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: drawerWidth,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CustomDrawer(), // Use the optimized drawer
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  

  // Get shape of menu button based on position
  BorderRadius _getButtonBorderRadius() {
    final size = MediaQuery.of(context).size;

    // If near right edge, make semi-circular
    if (_buttonX >= size.width - 70) {
      return const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      );
    }
    // If near left edge, make semi-circular from right
    else if (_buttonX <= 70) {
      return const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      );
    }
    // Otherwise, make fully circular
    return BorderRadius.circular(30);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main draggable menu button
        Positioned(
          left: _buttonX,
          top: _buttonY - 25, // Center vertically
          child: Draggable(
            feedback: Material(
              color: Colors.orange.withOpacity(0.8),
              borderRadius: _getButtonBorderRadius(),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Material(
                color: Colors.orange,
                borderRadius: _getButtonBorderRadius(),
                child: Container(width: 50, height: 50),
              ),
            ),
            onDragEnd: (details) {
              setState(() {
                // Update position based on where drag ended
                _buttonX = (details.offset.dx).clamp(0.0, size.width - 50);
                _buttonY = (details.offset.dy + 25).clamp(
                  50.0,
                  size.height - 50,
                );

                // Close menu when dragging ends
                if (_isExpanded) {
                  _isExpanded = false;
                  _animationController.reverse();
                }
              });
            },
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Material(
                elevation: 4,
                color: Colors.orange,
                borderRadius: _getButtonBorderRadius(),
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _animation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Top features (visible only when expanded)
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY - 25 - (_topIcons.length * 52),
            child: _buildIconsContainer(_topIcons, context),
          ),

        // Bottom features (visible only when expanded)
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY + 33,
            child: _buildIconsContainer(_bottomIcons, context),
          ),
      ],
    );
  }

  Widget _buildIconsContainer(
    List<Map<String, dynamic>> iconItems,
    BuildContext context,
  ) {
    final size = MediaQuery.of(context).size;

    // Determine border radius based on position
    BorderRadius borderRadius;
    if (_buttonX >= size.width - 70) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(25),
        bottomLeft: Radius.circular(25),
      );
    } else if (_buttonX <= 70) {
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(25),
        bottomRight: Radius.circular(25),
      );
    } else {
      borderRadius = BorderRadius.circular(25);
    }

    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(-1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            iconItems
                .map(
                  (item) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => _handleIconPress(item['action'], context),
                      child: Tooltip(
                        message: item['name'],
                        child: Container(
                          height: 50,
                          width: 50,
                          alignment: Alignment.center,
                          child: Icon(
                            item['icon'],
                            color: Colors.orange,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

// Custom Search Delegate remains unchanged
class CustomSearchDelegate extends SearchDelegate {
  final List<String> searchExamples = [
    'Golf courses',
    'Friends',
    'Events',
    'Messages',
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<String> matchQuery = [];
    for (var item in searchExamples) {
      if (item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(matchQuery[index]),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: ${matchQuery[index]}')),
            );
            close(context, matchQuery[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var item in searchExamples) {
      if (item.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(item);
      }
    }
    return ListView.builder(
      itemCount: matchQuery.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(matchQuery[index]),
          onTap: () {
            query = matchQuery[index];
            showResults(context);
          },
        );
      },
    );
  }
}


class SmoothDrawerService {
  static void showLeftDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, _) {
          final drawerWidth = math.min(
            MediaQuery.of(context).size.width * 0.8,
            300.0,
          );

          return _SmoothDrawerOverlay(
            animation: animation,
            drawerWidth: drawerWidth,
          );
        },
      ),
    );
  }
}

class _SmoothDrawerOverlay extends StatelessWidget {
  final Animation<double> animation;
  final double drawerWidth;

  const _SmoothDrawerOverlay({
    required this.animation,
    required this.drawerWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Create multiple animation curves for different elements
    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0), // Custom bezier curve
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    final scaleAnimation = CurvedAnimation(
      parent: animation,
      curve: const ElasticOutCurve(0.8),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background overlay with tap to dismiss
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.5 * animation.value),
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),

          // Drawer with smooth animations
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -drawerWidth * (1 - slideAnimation.value),
                  0,
                ),
                child: Opacity(
                  opacity: fadeAnimation.value,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * scaleAnimation.value),
                    alignment: Alignment.centerLeft,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: drawerWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20.0,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 40.0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: const CustomDrawer(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


