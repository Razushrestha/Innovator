import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SmoothDrawerService {
  static void showLeftDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300), // Reduced from 350
        reverseTransitionDuration: const Duration(milliseconds: 200), // Reduced from 250
        pageBuilder: (context, animation, _) {
          final drawerWidth = math.min(MediaQuery.of(context).size.width * 0.8, 300.0);
          return _SmoothDrawerOverlay(animation: animation, drawerWidth: drawerWidth);
        },
      ),
    );
  }
}

class _SmoothDrawerOverlay extends StatelessWidget {
  final Animation<double> animation;
  final double drawerWidth;

  const _SmoothDrawerOverlay({required this.animation, required this.drawerWidth});

  @override
  Widget build(BuildContext context) {
    // Optimized animation curves
    final slideAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic, // Changed from custom Cubic
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < 0) {
            final delta = details.delta.dx.abs() / drawerWidth;
            if (delta > 0.001) {
              Navigator.of(context).pop();
            }
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx < -200) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Optimized backdrop
            AnimatedBuilder(
              animation: fadeAnimation,
              builder: (context, _) => GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withOpacity(0.5 * fadeAnimation.value),
                ),
              ),
            ),
        
            // Optimized drawer animation
            AnimatedBuilder(
              animation: slideAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(-drawerWidth * (1 - slideAnimation.value), 0),
                child: child,
              ),
              child: Opacity(
                opacity: fadeAnimation.value,
                child: _buildDrawerContainer(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerContainer(BuildContext context) {
    return Align(
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
    );
  }
}

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with TickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  bool _isLoadingFromCache = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingFromCache = true;
    });

    final cachedProfile = await DrawerProfileCache.getCachedProfile();
    if (cachedProfile != null) {
      if (mounted) {
        setState(() {
          _userData = {
            'name': cachedProfile.name,
            'email': cachedProfile.email,
            'picture': cachedProfile.picturePath,
          };
          AppData().setCurrentUser(_userData!);
          Get.find<UserController>().updateProfilePicture(cachedProfile.picturePath ?? '');
          _isLoading = false;
          _isLoadingFromCache = false;
        });
      }
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final bool hasInternet = await _checkInternetConnection();
    if (hasInternet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchUserProfile();
       // _loadNotifications();
      });
    } else if (cachedProfile == null) {
      _handleError('No internet connection and no cached profile available');
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final String? authToken = AppData().authToken;
      if (authToken == null || authToken.isEmpty) {
        _handleError('Authentication token not found');
        return;
      }

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final userData = responseData['data'];
          await DrawerProfileCache.cacheProfile(
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            picturePath: userData['picture'],
          );

          if (userData['picture'] != null) {
            const baseUrl = 'http://182.93.94.210:3064';
            await precacheImage(
              CachedNetworkImageProvider('$baseUrl${userData['picture']}'),
              context,
            );
          }

          Get.find<UserController>().updateProfilePicture(userData['picture']);
          if (mounted) {
            setState(() {
              _userData = userData;
              _isLoading = false;
              AppData().setCurrentUser(_userData!);
            });
          }
        } else {
          _handleError(responseData['message'] ?? 'Unknown error');
        }
      } else {
        _handleError('Failed to load profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Network error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
        _isLoadingFromCache = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppData().authToken}',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _unreadCount = data['data']['unreadCount'] ?? 0;
            _notifications = (data['data']['notifications'] as List)
                .map((json) => NotificationModel.fromJson(json))
                .toList();
          });
        }
      } else {
        developer.log('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ClipPath(
          clipper: DrawerClipper(),
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnimation.value * 300, 0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildGradientHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 _buildAnimatedMenuItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    badge: _unreadCount > 0 ? _unreadCount.toString() : null,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => ProviderScope(
                            child: NotificationListScreen(),
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    delay: 0,
                  ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.message_rounded,
                                  title: 'Messages',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatListScreen(
                                          currentUserId: AppData().currentUserId ?? '',
                                          currentUserName: AppData().currentUserName ?? '',
                                          currentUserPicture: AppData().currentUserProfilePicture ?? '',
                                          currentUserEmail: AppData().currentUserEmail ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  delay: 100,
                                ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.person_rounded,
                                  title: 'Profile',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProviderScope(
                                          child: UserProfileScreen(userId: AppData().currentUserId ?? ''),
                                        ),
                                      ),
                                    );
                                  },
                                  delay: 200,
                                ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.psychology_rounded,
                                  title: 'Eliza ChatBot',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) =>  ElizaChatScreen()),
                                    );
                                  },
                                  delay: 300,
                                ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.report_rounded,
                                  title: 'Reports',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) =>  ReportsScreen()),
                                    );
                                  },
                                  delay: 400,
                                ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.privacy_tip_rounded,
                                  title: 'Privacy & Policy',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProviderScope(child: PrivacyPolicy()),
                                      ),
                                    );
                                  },
                                  delay: 500,
                                ),
                                _buildAnimatedMenuItem(
                                  icon: Icons.help_rounded,
                                  title: 'FAQ',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const FAQScreen()),
                                    );
                                  },
                                  delay: 600,
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                                _buildGradientDivider(),
                                _buildAnimatedMenuItem(
                                  icon: Icons.logout_rounded,
                                  title: 'Logout',
                                  isLogout: true,
                                  onTap: _showLogoutDialog,
                                  delay: 700,
                                ),
                                const SizedBox(height: 15),
                                _buildFooter(),
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEB6B46),
            const Color(0xFFFF8A65),
            const Color(0xFFEB6B46).withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB6B46).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: HeaderPatternPainter())),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : _errorMessage != null && _userData == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset('animation/No-Content.json'),
                              const SizedBox(height: 10),
                              const Text(
                                'Offline: Please connect to the internet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _buildAdvancedProfileHeader(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedProfileHeader() {
    final userData = AppData().currentUser ?? _userData;
    final String name = userData?['name'] ?? 'User';
    final String email = userData?['email'] ?? '';
    const String baseUrl = 'http://182.93.94.210:3064';

    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontFamily: 'Roboto',
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() {
            final picturePath = Get.find<UserController>().profilePicture;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: picturePath != null
                    ? CachedNetworkImage(
                        imageUrl: '$baseUrl$picturePath',
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 35,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.white,
                        ),
                        cacheManager: CacheManager(
                          Config(
                            'profilePictureCache',
                            stalePeriod: const Duration(days: 30),
                                  maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: 'profilePictureCache'),

                          ),
                        ),
                        placeholderFadeInDuration: const Duration(milliseconds: 200),
  fadeOutDuration: const Duration(milliseconds: 200),
  fadeInDuration: const Duration(milliseconds: 200),
                      )
                    : const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int delay,
    String? badge,
    bool isLogout = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isLogout
                    ? LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.3),
                        ],
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLogout
                                ? Colors.red.withOpacity(0.1)
                                : const Color(0xFFEB6B46).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: isLogout ? Colors.red : const Color(0xFFEB6B46),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLogout ? Colors.red : Colors.grey.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                      ],
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

  Widget _buildGradientDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEB6B46).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Color(0xFFEB6B46),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Innovator App v1.0.11',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Powered by Nepatronix',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout Confirmation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                await AppData().clearAuthToken();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 30, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 30);
    path.lineTo(size.width, size.height - 30);
    path.quadraticBezierTo(size.width, size.height, size.width - 30, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    for (double x = 0; x <= size.width; x += 20) {
      final y = size.height * 0.3 + 20 * math.sin((x / size.width) * 2 * math.pi);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 40, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.6), 25, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 15, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}