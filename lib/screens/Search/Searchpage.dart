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
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchSuggestedUsers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Animated Background
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
                        // Header Section
                        _buildHeader(isDarkMode),
                        
                        // Search Section
                        _buildSearchSection(isDarkMode),
                        
                        // Content Section
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
                    ]
                  : [
                    Color.fromRGBO(244, 135, 6, 1),
                      const Color(0xFFE3F2FD),
                     Color.fromRGBO(244, 135, 6, 1),
                    ],
            ),
          ),
          child: CustomPaint(
            painter: ParticlePainter(_particleController.value, isDarkMode),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.purple.shade400, Colors.blue.shade400]
                    : [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Find amazing people to connect with',
                  style: TextStyle(
                    fontSize: 14,
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.grey[800]!.withOpacity(0.3),
                      Colors.grey[900]!.withOpacity(0.3),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      Colors.grey[50]!.withOpacity(0.9),
                    ],
            ),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search amazing people...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                        size: 22,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding amazing people...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Section Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isSearching ? 'Search Results' : 'Suggested People',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (!_isSearching)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.purple.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_suggestedUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // User List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = _isSearching ? _searchResults[index] : _suggestedUsers[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  child: _buildEnhancedUserTile(user, context, index),
                );
              },
              childCount: _isSearching ? _searchResults.length : _suggestedUsers.length,
            ),
          ),

          // Empty State
          if (_isSearching && _searchResults.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(isDarkMode),
            ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
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
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, _) => SpecificUserProfilePage(userId: user['_id']),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // gradient: LinearGradient(
                      //   colors: isDarkMode
                      //       ? [
                      //           Colors.grey[800]!.withOpacity(0.3),
                      //           Colors.grey[850]!.withOpacity(0.3),
                      //         ]
                      //       : [
                      //           Colors.white.withOpacity(0.9),
                      //           Colors.grey[50]!.withOpacity(0.9),
                      //         ],
                      // ),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Row(
                          children: [
                            // Enhanced Avatar
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                // gradient: LinearGradient(
                                //   colors: [
                                //     Colors.blue.shade400,
                                //     Colors.purple.shade400,
                                //   ],
                                // ),
                                // boxShadow: [
                                //   BoxShadow(
                                //     color: Colors.blue.withOpacity(0.3),
                                //     blurRadius: 10,
                                //     offset: const Offset(0, 4),
                                //   ),
                                // ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: isCurrentUser
                                  ? Obx(
                                      () => CircleAvatar(
                                        
                                        radius: 28,
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
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 28,
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
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Text(
                                  //   user['email'] ?? 'No email',
                                  //   style: TextStyle(
                                  //     fontSize: 14,
                                  //     color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  //   ),
                                  // ),
                                  // const SizedBox(height: 8),
                                  // Row(
                                  //   children: [
                                  //     Icon(
                                  //       Icons.person_outline,
                                  //       size: 16,
                                  //       color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  //     ),
                                  //     // const SizedBox(width: 4),
                                  //     // Text(
                                  //     //   'Connect',
                                  //     //   style: TextStyle(
                                  //     //     fontSize: 12,
                                  //     //     color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  //     //   ),
                                  //     // ),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                            
                            // Enhanced Follow Button
                            // FutureBuilder<bool>(
                            //   future: FollowService.checkFollowStatus(user['email'] ?? ''),
                            //   builder: (context, snapshot) {
                            //     if (snapshot.connectionState == ConnectionState.waiting) {
                            //       return Container(
                            //         width: 40,
                            //         height: 40,
                            //         decoration: BoxDecoration(
                            //           gradient: LinearGradient(
                            //             colors: [Colors.blue.shade400, Colors.purple.shade400],
                            //           ),
                            //           borderRadius: BorderRadius.circular(20),
                            //         ),
                            //         child: const Center(
                            //           child: SizedBox(
                            //             width: 20,
                            //             height: 20,
                            //             child: CircularProgressIndicator(
                            //               strokeWidth: 2,
                            //               color: Colors.white,
                            //             ),
                            //           ),
                            //         ),
                            //       );
                            //     }

                            //     // final isFollowing = snapshot.data ?? false;
                            //     // return Container(
                            //     //   decoration: BoxDecoration(
                            //     //     gradient: LinearGradient(
                            //     //       colors: isFollowing
                            //     //           ? [Colors.grey.shade600, Colors.grey.shade700]
                            //     //           : [Colors.blue.shade400, Colors.purple.shade400],
                            //     //     ),
                            //     //     borderRadius: BorderRadius.circular(20),
                            //     //     boxShadow: [
                            //     //       BoxShadow(
                            //     //         color: (isFollowing ? Colors.grey : Colors.blue).withOpacity(0.3),
                            //     //         blurRadius: 8,
                            //     //         offset: const Offset(0, 4),
                            //     //       ),
                            //     //     ],
                            //     //   ),
                            //     //   // child: FollowButton(
                            //     //   //   targetUserEmail: user['email'] ?? '',
                            //     //   //   initialFollowStatus: isFollowing,
                            //     //   //   onFollowSuccess: () {
                            //     //   //     setState(() {});
                            //     //   //   },
                            //     //   //   onUnfollowSuccess: () {
                            //     //   //     setState(() {});
                            //     //   //   },
                            //     //   //   size: 40,
                            //     //   // ),
                            //     // );
                            //   },
                            // ),
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
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms\nor discover new people below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  ParticlePainter(this.animationValue, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.blue).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final offset = Offset(
        x + sin(animationValue * 2 * pi + i) * 20,
        y + cos(animationValue * 2 * pi + i) * 20,
      );
      
      canvas.drawCircle(offset, random.nextDouble() * 3 + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add this import at the top of the file
