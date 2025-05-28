import 'dart:async';

import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/basic_electronic.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

// Category data model
class Category {
  final String title;
  final String courses;
  final IconData iconData;
  final Color color;
  final String type;

  Category({
    required this.title,
    required this.courses,
    required this.iconData,
    required this.color,
    required this.type,
  });
}

// BasicElectronic screen (destination for all category taps)
class BasicElectronic extends StatelessWidget {
  const BasicElectronic({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Electronics')),
      body: const Center(
        child: Text(
          'Welcome to Basic Electronics!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  String _greeting = "Good Morning";
  String _searchQuery = "";
  String _selectedFilter = "All";
  List<String> _filterTypes = [
    "All",
    "Electronics",
    "Robotics",
    "IoT",
    "AI/ML",
    "Others",
  ];
  late List<Category> _filteredCategories;
  Timer? _timer;

  // List of categories
  final List<Category> _categories = [
    Category(
      title: 'Basic Electronics',
      courses: '55 courses',
      iconData: Icons.electrical_services,
      color: Colors.blue.shade50,
      type: 'Electronics',
    ),
    Category(
      title: 'Notes',
      courses: '20 courses',
      iconData: Icons.notes,
      color: Colors.amber.shade50,
      type: 'Others',
    ),
    Category(
      title: 'Robotics',
      courses: '16 courses',
      iconData: Icons.smart_toy,
      color: Colors.green.shade50,
      type: 'Robotics',
    ),
    Category(
      title: 'IoT',
      courses: '25 courses',
      iconData: Icons.devices,
      color: Colors.purple.shade50,
      type: 'IoT',
    ),
    Category(
      title: 'IoT & Robotics',
      courses: '25 courses',
      iconData: Icons.devices_other,
      color: Colors.indigo.shade50,
      type: 'IoT',
    ),
    Category(
      title: 'Projects',
      courses: '25 courses',
      iconData: Icons.build,
      color: Colors.orange.shade50,
      type: 'Others',
    ),
    Category(
      title: 'AI with Robotics',
      courses: '20 courses',
      iconData: Icons.psychology,
      color: Colors.red.shade50,
      type: 'AI/ML',
    ),
    Category(
      title: 'ML with Robotics',
      courses: '20 courses',
      iconData: Icons.auto_awesome,
      color: Colors.teal.shade50,
      type: 'AI/ML',
    ),
    Category(
      title: 'PCB Design',
      courses: '20 courses',
      iconData: Icons.developer_board,
      color: Colors.cyan.shade50,
      type: 'Electronics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _filteredCategories = [..._categories];

    // Update greeting every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreeting();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Update greeting based on time of day
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning";
      } else if (hour < 17) {
        _greeting = "Good Afternoon";
      } else {
        _greeting = "Good Evening";
      }
    });
  }

  // Filter categories based on search query and selected filter
  void _filterCategories() {
    setState(() {
      _filteredCategories =
          _categories.where((category) {
            // Filter by search query
            final matchesSearch = category.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

            // Filter by category type
            final matchesFilter =
                _selectedFilter == "All" || category.type == _selectedFilter;

            return matchesSearch && matchesFilter;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            key: _scaffoldKey, // Add the scaffold key here

      body: Stack(
        children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
             // _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: SingleChildScrollView(child: _buildCategoriesSection()),
              ),
             // _buildBottomNavBar(),
            ],
          ),
        ),
        FloatingMenuWidget(scaffoldKey: _scaffoldKey,)
        ]
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              const SizedBox(height: 4),
              Text(
                _greeting ,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(AppData().currentUserName ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
            ],
          ),
          // IconButton(
          //   icon: const Icon(Icons.notifications_outlined),
          //   onPressed: () {},
          //   iconSize: 28,
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search your topic',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterCategories();
                  });
                },
              ),
            ),
            Icon(Icons.mic, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final type = _filterTypes[index];
          final isSelected = _selectedFilter == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = type;
                  _filterCategories();
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              //TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),
        ),
        _filteredCategories.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No categories match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
            : GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(_filteredCategories[index]);
              },
            ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        // Navigate to BasicElectronic screen for any category tap
       showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Category Tapped'),
      content: Text('You tapped on "${category.title}".'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
      },
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon with a circular background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(category.iconData, size: 32, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            // Category title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                category.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Number of courses
            Text(
              category.courses,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.star, 'Featured'),
          _buildNavItem(1, Icons.play_circle_outline, 'My Learning'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.indigo : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.indigo : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


