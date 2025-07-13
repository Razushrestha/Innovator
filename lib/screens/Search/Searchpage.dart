import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Follow/follow-Service.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:ui';
import '../../controllers/user_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final AppData _appData = AppData();
  List<dynamic> _searchResults = [];
  List<dynamic> _suggestedUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Enhanced Color Palette
  static const Color primaryOrange = Color.fromRGBO(244, 135, 6, 1);
  static const Color secondaryOrange = Color.fromRGBO(255, 152, 0, 1);
  static const Color accentOrange = Color.fromRGBO(255, 193, 7, 1);
  static const Color deepOrange = Color.fromRGBO(230, 81, 0, 1);
  static const Color lightOrange = Color.fromRGBO(255, 224, 178, 1);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchSuggestedUsers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<dynamic> _filterUniqueUsers(List<dynamic> users) {
    final uniqueEmails = <String>{};
    return users.where((user) {
      final email = user['email'] ?? '';
      if (email.isEmpty || uniqueEmails.contains(email)) {
        return false;
      }
      uniqueEmails.add(email);
      return true;
    }).toList();
  }

  Future<void> _fetchSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        setState(() {
          _suggestedUsers = data.take(8).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading suggestions: $e');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3066/api/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = _filterUniqueUsers(json.decode(response.body)['data']);
        setState(() {
          _searchResults = data
              .where((user) =>
                  user['name']
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false)
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error searching users: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Enhanced Animated Background
          _buildAnimatedBackground(isDarkMode),
          
          // Main Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        // Enhanced Header Section
                        _buildHeader(isDarkMode),
                        
                        // Enhanced Search Section
                        _buildSearchSection(isDarkMode),
                        
                        // Enhanced Content Section
                        Expanded(
                          child: _buildContentSection(isDarkMode),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          FloatingMenuWidget(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF0F0F23),
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                      primaryOrange.withOpacity(0.05),
                    ]
                  : [
                      const Color(0xFFFFF8E1),
                      const Color(0xFFFFF3E0),
                      lightOrange.withOpacity(0.3),
                      primaryOrange.withOpacity(0.1),
                    ],
            ),
          ),
          child: CustomPaint(
            painter: EnhancedParticlePainter(_particleController.value, isDarkMode),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Enhanced Icon Container
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryOrange,
                        secondaryOrange,
                        accentOrange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      primaryOrange,
                      deepOrange,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with amazing people around you',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.grey[800]!.withOpacity(0.4),
                      Colors.grey[900]!.withOpacity(0.6),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.grey[50]!.withOpacity(0.95),
                    ],
            ),
            border: Border.all(
              color: isDarkMode
                  ? primaryOrange.withOpacity(0.3)
                  : primaryOrange.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for amazing people...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 17,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryOrange.withOpacity(0.8), secondaryOrange.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.clear_rounded,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _searchUsers(value);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryOrange,
                    secondaryOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Finding amazing people...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced Section Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryOrange, deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isSearching ? 'Search Results' : 'Suggested People',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (!_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryOrange, secondaryOrange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_suggestedUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Enhanced User List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = _isSearching ? _searchResults[index] : _suggestedUsers[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  child: _buildEnhancedUserTile(user, context, index),
                );
              },
              childCount: _isSearching ? _searchResults.length : _suggestedUsers.length,
            ),
          ),

          // Enhanced Empty State
          if (_isSearching && _searchResults.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(isDarkMode),
            ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedUserTile(Map<String, dynamic> user, BuildContext context, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userController = Get.find<UserController>();
    final isCurrentUser = user['_id'] == AppData().currentUserId;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, _) => SpecificUserProfilePage(userId: user['_id']),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                Colors.grey[800]!.withOpacity(0.4),
                                Colors.grey[850]!.withOpacity(0.6),
                              ]
                            : [
                                Colors.white.withOpacity(0.95),
                                Colors.grey[50]!.withOpacity(0.95),
                              ],
                      ),
                      border: Border.all(
                        color: isDarkMode
                            ? primaryOrange.withOpacity(0.2)
                            : primaryOrange.withOpacity(0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Row(
                          children: [
                            // Enhanced Avatar with Gradient Border
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: [
                                    primaryOrange,
                                    secondaryOrange,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: isCurrentUser
                                  ? Obx(
                                      () => CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.grey[300],
                                        key: ValueKey('search_avatar_${user['_id']}_${userController.profilePictureVersion.value}'),
                                        backgroundImage: userController.profilePicture.value != null &&
                                                userController.profilePicture.value!.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                '${userController.getFullProfilePicturePath()}?v=${userController.profilePictureVersion.value}',
                                              )
                                            : null,
                                        child: userController.profilePicture.value == null ||
                                                userController.profilePicture.value!.isEmpty
                                            ? Text(
                                                user['name']?[0] ?? '?',
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: user['picture'] != null && user['picture'].isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              'http://182.93.94.210:3066${user['picture']}?t=${DateTime.now().millisecondsSinceEpoch}',
                                            )
                                          : null,
                                      child: user['picture'] == null || user['picture'].isEmpty
                                          ? Text(
                                              user['name']?[0] ?? '?',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                            ),
                            
                            const SizedBox(width: 20),
                            
                            // Enhanced User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: primaryOrange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tap to connect',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Enhanced Action Button
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryOrange, secondaryOrange],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryOrange, secondaryOrange],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search terms\nor discover new people below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  EnhancedParticlePainter(this.animationValue, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = Random(42);
    
    // Create multiple layers of particles
    for (int layer = 0; layer < 3; layer++) {
      final layerOpacity = (isDarkMode ? 0.1 : 0.08) / (layer + 1);
      paint.color = (isDarkMode 
          ? const Color.fromRGBO(244, 135, 6, 1) 
          : const Color.fromRGBO(244, 135, 6, 1)).withOpacity(layerOpacity);
      
      for (int i = 0; i < 30; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final speed = 0.5 + (layer * 0.3);
        final offset = Offset(
          x + sin(animationValue * 2 * pi * speed + i + layer) * (20 + layer * 10),
          y + cos(animationValue * 2 * pi * speed + i + layer) * (20 + layer * 10),
        );
        
        final radius = random.nextDouble() * (4 + layer) + 1;
        canvas.drawCircle(offset, radius, paint);
      }
    }
    
    // Add floating geometric shapes
    final shapePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (isDarkMode 
          ? const Color.fromRGBO(244, 135, 6, 1) 
          : const Color.fromRGBO(244, 135, 6, 1)).withOpacity(0.05);
    
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = Offset(
        x + sin(animationValue * pi + i * 0.5) * 30,
        y + cos(animationValue * pi + i * 0.5) * 30,
      );
      
      final shapeSize = 20.0 + random.nextDouble() * 20;
      final rect = Rect.fromCenter(center: offset, width: shapeSize, height: shapeSize);
      
      if (i % 3 == 0) {
        canvas.drawRect(rect, shapePaint);
      } else if (i % 3 == 1) {
        canvas.drawOval(rect, shapePaint);
      } else {
        final path = Path()
          ..moveTo(offset.dx, offset.dy - shapeSize / 2)
          ..lineTo(offset.dx - shapeSize / 2, offset.dy + shapeSize / 2)
          ..lineTo(offset.dx + shapeSize / 2, offset.dy + shapeSize / 2)
          ..close();
        canvas.drawPath(path, shapePaint);
      }
    }
    
    // Add glowing orbs
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = Offset(
        x + sin(animationValue * 1.5 * pi + i * 1.2) * 40,
        y + cos(animationValue * 1.5 * pi + i * 1.2) * 40,
      );
      
      glowPaint.color = const Color.fromRGBO(244, 135, 6, 1)
          .withOpacity(isDarkMode ? 0.15 : 0.08);
      canvas.drawCircle(offset, 15 + random.nextDouble() * 10, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}