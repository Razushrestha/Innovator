// floating_menu_widget.dart
import 'package:flutter/material.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/sample/screens/home_page.dart';
import 'package:innovator/screens/Add_Content/Create_post.dart';
import 'package:innovator/screens/Shop/shop_page.dart';
import 'package:innovator/widget/auth_check.dart';

import '../screens/Profile/profile_page.dart';

class FloatingMenuWidget extends StatefulWidget {
  const FloatingMenuWidget({Key? key}) : super(key: key);

  @override
  _FloatingMenuWidgetState createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends State<FloatingMenuWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Features to display above the menu button with their respective actions
  final List<Map<String, dynamic>> _topIcons = [
    {
      'icon': Icons.library_books,
      'name': 'Golf Course',
      'action': 'navigate_golf',
    },
    {'icon': Icons.shop, 'name': 'Search', 'action': 'open_search'},
    {'icon': Icons.add_a_photo, 'name': 'Search', 'action': 'add_photo'},
  ];

  // Features to display below the menu button with their respective actions
  final List<Map<String, dynamic>> _bottomIcons = [
    {'icon': Icons.shop, 'name': 'Settings', 'action': 'open_settings'},
    {'icon': Icons.person, 'name': 'Profile', 'action': 'view_profile'},
    {'icon': Icons.menu, 'name': 'Drawer', 'action': 'drawer'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Opening Golf Course'))
        // );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
        break;

      case 'open_search':
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Opening Search'))
        // );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Course_HomePage()),
        );
        break;

      case 'add_photo':
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(const SnackBar(content: Text('Opening Photo')));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreatePostScreen()),
        );
        break;

      case 'open_settings':
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Opening Settings')),
        // showSearch(
        //   context: context,
        //   delegate: CustomSearchDelegate(),
        // );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => shop_page()),
          (route) => true,
        );
        break;

      case 'view_profile':
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Opening Profile'))
        // );
        Navigator.of(context).pushReplacement(
          // Example usage in main.dart or in a router configuration
          MaterialPageRoute(
            builder: (_) => AuthCheck(child: UserProfileScreen()),
          ),
        );
        break;

      case 'drawer':
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented yet: $action')),
        );
    }
    // Keep menu expanded if needed or toggle as required
    // If you want menu to stay open when navigating, remove this line
    // If you want it to close after selection, keep this line
    // if (_isExpanded) {
    //   _toggleMenu();
    // }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size
    final Size mq = MediaQuery.of(context).size;

    // Calculate the fixed center position for the menu button
    final double menuButtonCenterY =
        mq.height * 0.47 + 25; // 25 is half the height of the button

    return Stack(
      clipBehavior:
          Clip.none, // Allow children to be positioned outside stack bounds
      children: [
        // The main menu button - always at the same position
        Positioned(
          top: menuButtonCenterY - 25, // Centered position minus half height
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              elevation: 4,
              color: Colors.orange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
              child: InkWell(
                onTap: _toggleMenu,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
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
            bottom: menuButtonCenterY + 33, // Position above the menu button
            right: 0,
            child: _buildIconsContainer(_topIcons, context),
          ),

        // Bottom features (visible only when expanded)
        if (_isExpanded)
          Positioned(
            top: menuButtonCenterY + 33, // Position below the menu button
            right: 0,
            child: _buildIconsContainer(_bottomIcons, context),
          ),
      ],
    );
  }

  Widget _buildIconsContainer(
    List<Map<String, dynamic>> iconItems,
    BuildContext context,
  ) {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
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

// Custom Search Delegate for the search functionality
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
/*
b asb
snfjof  jvdj  hvfhbk fe ef
l akbd 
m idbfv ekf 
 sf cjbdvijbe
  dk vkb 
   kd fkjbfh
   df kjdbfkjb
   d v vdjkkf
   d k dkjvbjkv
   skckjdbkjdfk
   sd c dvkn dv
   d k kdv
   dm cdv n d
   dn dvfd
nkjbdsfjbhdfs
 dsfnmkdfs
  d ndvmnds
  d f kdvkds
  dvmn dvnm mnsv
  dm ndvnmnsdf

*/ 
