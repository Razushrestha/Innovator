import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/utils/Drawer/custom_drawer.dart';
import 'package:lottie/lottie.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/Notification/FCM_Services.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/screens/F&Q/F&Qscreen.dart';
import 'package:innovator/screens/Privacy_Policy/privacy_screen.dart';
import 'package:innovator/screens/Profile/profile_page.dart';
import 'package:innovator/screens/Report/Report_screen.dart';
import 'package:innovator/screens/chatrrom/Screen/chat_listscreen.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Add_Content/Create_post.dart';
import 'package:innovator/screens/Course/home.dart';
import 'package:innovator/screens/Search/Searchpage.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';

class FloatingMenuWidget extends StatefulWidget {
  const FloatingMenuWidget({super.key});

  @override
  _FloatingMenuWidgetState createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends State<FloatingMenuWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _buttonX = 0;
  double _buttonY = 0;

  final List<Map<String, dynamic>> _topIcons = [
    {'icon': Icons.home, 'name': 'FEED', 'action': 'navigate_golf'},
    {'icon': Icons.school, 'name': 'COURSE', 'action': 'open_search'},
    {'icon': Icons.add_a_photo, 'name': 'ADD POST', 'action': 'add_photo'},
  ];

  final List<Map<String, dynamic>> _bottomIcons = [
    {'icon': Icons.shop, 'name': 'SHOP', 'action': 'open_settings'},
    {'icon': Icons.search, 'name': 'SEARCH', 'action': 'view_profile'},
    {'icon': Icons.menu, 'name': 'Drawer', 'action': 'drawer'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
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

  void _handleIconPress(String action, BuildContext context) {
    switch (action) {
      case 'navigate_golf':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
        break;
      case 'open_search':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProviderScope(child: HomeScreen())),
        );
        break;
      case 'add_photo':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        break;
      case 'open_settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopPage()),
        );
        break;
      case 'view_profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
        break;
      case 'drawer':
        SmoothDrawerService.showLeftDrawer(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented: $action')),
        );
    }
  }

  BorderRadius _getButtonBorderRadius() {
    final size = MediaQuery.of(context).size;
    if (_buttonX >= size.width - 70) {
      return const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      );
    } else if (_buttonX <= 70) {
      return const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      );
    }
    return BorderRadius.circular(30);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: _buttonX,
          top: _buttonY - 25,
          child: Draggable(
            feedback: Material(
              color: Colors.orange.withOpacity(0.8),
              borderRadius: _getButtonBorderRadius(),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
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
                _buttonX = (details.offset.dx).clamp(0.0, size.width - 50);
                _buttonY = (details.offset.dy + 25).clamp(50.0, size.height - 50);
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
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY - 25 - (_topIcons.length * 52),
            child: _buildIconsContainer(_topIcons, context),
          ),
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY + 33,
            child: _buildIconsContainer(_bottomIcons, context),
          ),
      ],
    );
  }

  Widget _buildIconsContainer(List<Map<String, dynamic>> iconItems, BuildContext context) {
    final size = MediaQuery.of(context).size;
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
        children: iconItems.map((item) => Material(
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
        )).toList(),
      ),
    );
  }
}