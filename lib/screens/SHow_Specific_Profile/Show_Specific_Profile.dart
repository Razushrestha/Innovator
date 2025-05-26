import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:flutter/services.dart';
import 'package:innovator/screens/show_Specific_Profile/User_Image_Gallery.dart';
import 'package:innovator/screens/show_Specific_Profile/show_Specific_followers.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class SpecificUserProfilePage extends StatefulWidget {
  final String userId;

  const SpecificUserProfilePage({Key? key, required this.userId})
    : super(key: key);

  @override
  _SpecificUserProfilePageState createState() =>
      _SpecificUserProfilePageState();
}

class _SpecificUserProfilePageState extends State<SpecificUserProfilePage>
    with SingleTickerProviderStateMixin {
        final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<Map<String, dynamic>> _profileFuture;
  final AppData _appData = AppData();
  bool _isRefreshing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profileFuture = _fetchUserProfile();
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://182.93.94.210:3064/api/v1/stalk-profile/${widget.userId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authorization': 'Bearer ${_appData.authToken}',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      _profileFuture = _fetchUserProfile();
      await _profileFuture;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // IconButton(
          //   icon: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color:
          //           isDarkMode
          //               ? Colors.grey[800]!.withOpacity(0.7)
          //               : Colors.white.withOpacity(0.7),
          //       shape: BoxShape.circle,
          //     ),
          //     child: Icon(
          //       Icons.more_vert,
          //       color: isDarkMode ? Colors.white : Colors.black,
          //     ),
          //   ),
          //   onPressed: () {
          //     showModalBottomSheet(
          //       context: context,
          //       shape: const RoundedRectangleBorder(
          //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          //       ),
          //       builder: (context) => _buildOptionsSheet(),
          //     );
          //   },
          // ),
          // const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
        RefreshIndicator(
          onRefresh: _refreshProfile,
          color: Theme.of(context).primaryColor,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isRefreshing) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return _buildErrorView(snapshot.error.toString());
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No profile data available'));
              }
        
              final profileData = snapshot.data!;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(profileData, context),
                  ),
                  SliverToBoxAdapter(
                    child: _buildProfileInfo(profileData, context),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActionButtons(profileData, context),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAdditionalInfo(profileData, context),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  SliverToBoxAdapter(
                    child: UserImageGallery(
                      userEmail: profileData['email'] ?? widget.userId,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          ),
        ),
        FloatingMenuWidget(),
        ]
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final headerHeight = MediaQuery.of(context).size.height * 0.35;

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.3),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Profile content
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Profile picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'profile_picture_${profileData['_id']}',
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor:
                          isDarkMode
                              ? const Color.fromARGB(255, 184, 31, 31)
                              : Colors.white,
                      backgroundImage:
                          profileData['picture'] != null &&
                                  profileData['picture'].isNotEmpty
                              ? CachedNetworkImageProvider(
                                'http://182.93.94.210:3064${profileData['picture']}',
                              )
                              : null,
                      child:
                          profileData['picture'] == null ||
                                  profileData['picture'].isEmpty
                              ? Text(
                                profileData['name']?[0] ?? '?',
                                style: const TextStyle(fontSize: 40),
                              )
                              : null,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Name
                Text(
                  profileData['name'] ?? 'No name',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(
                      profileData['level'],
                    ).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLevelIcon(profileData['level']),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profileData['level']?.toString().toUpperCase() ??
                            'NO LEVEL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color:
            isDarkMode ? const Color.fromARGB(255, 141, 12, 12) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 141, 1, 1).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bio
          if (profileData['bio'] != null && profileData['bio'].isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileData['bio'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 30),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    profileData['followers']?.toString() ?? '0',
                    'Followers',
                    Icons.people,
                    context,
                  ),
                  VerticalDivider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    thickness: 1,
                    width: 1,
                  ),
                  _buildStatItem(
                    profileData['followings']?.toString() ?? '0',
                    'Following',
                    Icons.person_add,
                    context,
                  ),
                  if (profileData['friends'] == true) ...[
                    VerticalDivider(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      thickness: 1,
                      width: 1,
                    ),
                    _buildStatItem(
                      'Friends',
                      'Status',
                      Icons.verified,
                      context,
                      special: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    BuildContext context, {
    bool special = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate to followers/following list or show friends
          if (label == 'Followers') {
            showFollowersFollowingDialog(context, widget.userId);
          } else if (label == 'Following') {
            // Show friends list
            showFollowersFollowingDialog(context, widget.userId);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: special ? Colors.green : primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              special ? value : value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    special
                        ? Colors.green
                        : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          // Follow Button (Enhanced version of the existing one)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FollowButton(
              targetUserEmail: profileData['email'],
              initialFollowStatus: profileData['followed'] ?? false,
              onFollowSuccess: () => _refreshProfile(),
              onUnfollowSuccess: () => _refreshProfile(),
            ),
          ),

          const SizedBox(height: 16),

          // Message Button
          // SizedBox(
          //   width: double.infinity,
          //   height: 50,
          //   child: OutlinedButton.icon(
          //     icon: const Icon(Icons.message),
          //     label: const Text('Message'),
          //     style: OutlinedButton.styleFrom(
          //       foregroundColor: Theme.of(context).primaryColor,
          //       side: BorderSide(color: Theme.of(context).primaryColor),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //     onPressed: () {
          //       // Implement message functionality
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Message feature coming soon')),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(
    Map<String, dynamic> profileData,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
            child: Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                // Email
                _buildInfoTile(
                  Icons.email,
                  'Email',
                  profileData['email'] ?? 'Not provided',
                  context,
                  onTap: () {
                    // Copy email to clipboard
                    Clipboard.setData(
                      ClipboardData(text: profileData['email']),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email copied to clipboard'),
                      ),
                    );
                  },
                ),

                if (profileData['phone'] != null &&
                    profileData['phone'].isNotEmpty)
                  _buildInfoTile(
                    Icons.phone,
                    'Phone',
                    profileData['phone'],
                    context,
                    onTap: () {
                      // Copy phone to clipboard
                      Clipboard.setData(
                        ClipboardData(text: profileData['phone']),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number copied to clipboard'),
                        ),
                      );
                    },
                  ),

                if (profileData['location'] != null &&
                    profileData['location'].isNotEmpty)
                  _buildInfoTile(
                    Icons.location_on,
                    'Location',
                    profileData['location'],
                    context,
                  ),

                if (profileData['dob'] != null)
                  _buildInfoTile(
                    Icons.cake,
                    'Birthday',
                    _formatDate(profileData['dob']),
                    context,
                  ),

                _buildInfoTile(
                  Icons.update,
                  'Last Updated',
                  _formatDateTime(profileData['updatedAt']),
                  context,
                ),

                _buildInfoTile(
                  Icons.fingerprint,
                  'User ID',
                  profileData['_id'],
                  context,
                  onTap: () {
                    // Copy ID to clipboard
                    Clipboard.setData(ClipboardData(text: profileData['_id']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID copied to clipboard'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    BuildContext context, {
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.content_copy,
                size: 18,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSheet() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          _buildOptionTile(
            icon: Icons.share,
            label: 'Share Profile',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing profile...')),
              );
            },
          ),
          _buildOptionTile(
            icon: Icons.block,
            label: 'Block User',
            onTap: () {
              Navigator.pop(context);
              _showBlockConfirmationDialog();
            },
          ),
          _buildOptionTile(
            icon: Icons.flag,
            label: 'Report User',
            onTap: () {
              Navigator.pop(context);
              _showReportDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color:
              label == 'Report User' || label == 'Block User'
                  ? Colors.red
                  : theme.primaryColor,
        ),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _showBlockConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Block User'),
            content: const Text(
              'Are you sure you want to block this user? You will no longer see their content.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('User blocked')));
                },
                child: const Text('BLOCK', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please select a reason for reporting:'),
                const SizedBox(height: 16),
                _buildReportOption('Inappropriate content'),
                _buildReportOption('Harassment or bullying'),
                _buildReportOption('Spam or misleading'),
                _buildReportOption('Other'),
              ],
            ),
          ),
    );
  }

  Widget _buildReportOption(String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reported user for: $reason')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.circle, size: 12, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(reason),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32); // Richer bronze color
      case 'silver':
        return const Color(0xFFC0C0C0); // Silver
      case 'gold':
        return const Color(0xFFFFD700); // Gold
      case 'platinum':
        return const Color(0xFFE5E4E2); // Platinum
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.star;
      case 'gold':
        return Icons.emoji_events;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.person;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
