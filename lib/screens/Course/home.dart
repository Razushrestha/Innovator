import 'dart:async';
import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/screens/Course/sub_catg.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;
  String _greeting = "Good Morning";
  String _searchQuery = "";
  String _selectedFilter = "All";
  Timer? _timer;

  List<ParentCategory> _categories = [];
  List<ParentCategory> _filteredCategories = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateGreeting();
    _fetchCategories();

    // Update greeting every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreeting();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Fetch categories from API
  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.getParentCategories();
      
      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> categoriesJson = response['data'];
        final categories = categoriesJson
            .map((json) => ParentCategory.fromJson(json))
            .toList();

        setState(() {
          _categories = categories;
          _filteredCategories = [...categories];
          _isLoading = false;
        });

        developer.log('Loaded ${categories.length} categories');
      } else {
        throw Exception(response['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      developer.log('Error fetching categories: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
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

  // Filter categories based on search query
  void _filterCategories() {
    setState(() {
      _filteredCategories = _categories.where((category) {
        final matchesSearch = category.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        return matchesSearch;
      }).toList();
    });
  }

  // Navigate to subcategory screen
  void _navigateToSubcategory(ParentCategory category) {
    try {
      developer.log('Navigating to subcategory: ${category.name}');
      
      // Simple navigation without custom transitions to avoid issues
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryScreen(parentCategory: category),
        ),
      );
    } catch (e) {
      developer.log('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to ${category.name}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _hasError
                    ? _buildErrorWidget()
                    : _buildCategoriesSection(),
          ),
        ],
      ),
      floatingActionButton: const FloatingMenuWidget(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromRGBO(244, 135, 6, 1),
            const Color.fromRGBO(244, 135, 6, 1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppData().currentUserName ?? 'Welcome!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'What would you like to learn today?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search courses, categories...',
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade600,
          ),
          suffixIcon: Icon(
            Icons.mic,
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade600),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterCategories();
          });
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading categories...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: _fetchCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color.fromRGBO(244, 135, 6, 1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredCategories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCategories,
                  color: const Color.fromRGBO(244, 135, 6, 1),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(_filteredCategories[index], index);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ParentCategory category, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            developer.log('Category card tapped: ${category.name}');
            _navigateToSubcategory(category);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _parseColor(category.color),
                        _parseColor(category.color).withAlpha(70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getIconData(category.icon),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // Category Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip(
                            '${category.statistics.courses} courses',
                            Icons.play_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            '${category.statistics.videos} videos',
                            Icons.videocam_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(235, 111, 70, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color.fromRGBO(244, 135, 6, 1),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color.fromRGBO(244, 135, 6, 1);
    } catch (e) {
      return const Color.fromRGBO(244, 135, 6, 1);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'js':
        return Icons.javascript;
      case 'design':
        return Icons.design_services;
      case 'data':
        return Icons.analytics;
      case 'business':
        return Icons.business;
      case 'marketing':
        return Icons.campaign;
      case 'music':
        return Icons.music_note;
      case 'photo':
        return Icons.photo_camera;
      default:
        return Icons.category;
    }
  }
}