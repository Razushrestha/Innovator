import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Profile/profile_page.dart';
import 'package:innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:intl/intl.dart';
import 'package:innovator/screens/comment/comment_screen.dart';
import 'package:innovator/screens/Feed/post_detail_screen.dart';
import 'package:innovator/screens/Profile/profile_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<NotificationModel> notifications = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextCursor;
  bool hasMore = true;
  bool isDeletingAll = false;
  bool _showFilters = false;
  String _selectedFilter = 'all';
  
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _scrollController.addListener(_scrollListener);
    
    // Initialize animations
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        hasMore &&
        !isLoadingMore) {
      fetchMoreNotifications();
    }
  }

  // [Keep all your existing API methods: fetchNotifications, fetchMoreNotifications, 
  // markAsRead, markAllAsRead, deleteNotification, deleteAllNotifications, etc.]
  Future<void> fetchNotifications() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse('http://182.93.94.210:3066/api/v1/notifications');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> notificationData = jsonData['data']['notifications'];
        setState(() {
          notifications = notificationData
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          nextCursor = jsonData['data']['nextCursor'];
          hasMore = jsonData['data']['hasMore'];
        });
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchMoreNotifications() async {
    if (isLoadingMore || !hasMore || nextCursor == null) return;
    
    setState(() => isLoadingMore = true);
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse(
          'http://182.93.94.210:3066/api/v1/notifications?cursor=$nextCursor');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> notificationData = jsonData['data']['notifications'];
        setState(() {
          notifications.addAll(notificationData
              .map((json) => NotificationModel.fromJson(json))
              .toList());
          nextCursor = jsonData['data']['nextCursor'];
          hasMore = jsonData['data']['hasMore'];
        });
      } else {
        throw Exception('Failed to fetch more notifications: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching more notifications: $e');
    } finally {
      setState(() => isLoadingMore = false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/notifications/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'notificationIds': [notificationId]}),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            notifications[index] = notifications[index].copyWith(read: true);
          }
        });
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/notifications/mark-all-read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final modifiedCount = jsonData['data']['modifiedCount'] ?? 0;
        
        if (modifiedCount > 0) {
          setState(() {
            notifications = notifications.map((n) => n.copyWith(read: true)).toList();
          });
          _showSuccessSnackbar('All notifications marked as read');
        } else {
          _showInfoSnackbar('No unread notifications to mark');
        }
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('http://182.93.94.210:3066/api/v1/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => n.id == notificationId);
        });
        _showSuccessSnackbar('Notification deleted');
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    if (notifications.isEmpty) return;
    
    final confirmed = await _showStylizedDialog();
    if (confirmed != true) return;

    setState(() => isDeletingAll = true);
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('http://182.93.94.210:3066/api/v1/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => notifications.clear());
        _showSuccessSnackbar('All notifications deleted');
      } else {
        throw Exception('Failed to delete all notifications: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting all notifications: $e');
    } finally {
      setState(() => isDeletingAll = false);
    }
  }

  Future<bool?> _showStylizedDialog() {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Delete All Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This action cannot be undone. All your notifications will be permanently deleted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogButton(
                            'Cancel',
                            Colors.grey[100]!,
                            Colors.grey[700]!,
                            () => Navigator.pop(context, false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogButton(
                            'Delete All',
                            Colors.red,
                            Colors.white,
                            () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildDialogButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<NotificationModel> get filteredNotifications {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.read).toList();
      case 'messages':
        return notifications.where((n) => n.type.toLowerCase() == 'message').toList();
      case 'interactions':
        return notifications.where((n) => 
          ['like', 'comment', 'share', 'mention'].contains(n.type.toLowerCase())
        ).toList();
      default:
        return notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          _buildFilterChips(),
          _buildNotificationList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSliverAppBar() {
    final unreadCount = notifications.where((n) => !n.read).length;
    
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF48706),
                  const Color(0xFFF48706).withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => Homepage()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (notifications.isNotEmpty) ...[
                          _buildHeaderAction(
                            Icons.mark_email_read,
                            'Mark all read',
                            markAllAsRead,
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderAction(
                            Icons.delete_sweep,
                            'Delete all',
                            deleteAllNotifications,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: const TextStyle(
                                color: Color(0xFFF48706),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      leading: const SizedBox(),
    );
  }

  Widget _buildHeaderAction(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Unread', 'unread'),
              _buildFilterChip('Messages', 'messages'),
              _buildFilterChip('Interactions', 'interactions'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF48706) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFF48706) : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFF48706).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF48706)),
          ),
        ),
      );
    }

    final displayNotifications = filteredNotifications;

    if (displayNotifications.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == displayNotifications.length) {
            return _buildLoadMoreIndicator();
          }
          return _buildNotificationItem(displayNotifications[index], index);
        },
        childCount: displayNotifications.length + (hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all' 
              ? 'No notifications yet' 
              : 'No ${_selectedFilter} notifications',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
              ? 'When you get notifications, they\'ll show up here'
              : 'Try switching to a different filter',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: fetchNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF48706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: isLoadingMore
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF48706)),
              )
            : ElevatedButton(
                onPressed: fetchMoreNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF48706),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Load more'),
              ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildNotificationCard(notification),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: _buildDismissBackground(Colors.blue, Icons.mark_email_read, 'Mark as read'),
      secondaryBackground: _buildDismissBackground(Colors.red, Icons.delete, 'Delete'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as read
          if (!notification.read) {
            markAsRead(notification.id);
          }
          return false;
        } else {
          // Delete confirmation
          return await _showDeleteConfirmation();
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          deleteNotification(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          elevation: notification.read ? 1 : 3,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!notification.read) {
                markAsRead(notification.id);
              }
              _navigateToNotificationDetails(notification);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.read 
                    ? Colors.transparent 
                    : const Color(0xFFF48706).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationAvatar(notification),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationContent(notification),
                        const SizedBox(height: 8),
                        _buildNotificationMeta(notification),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildUnreadIndicator(notification),
                      const SizedBox(height: 8),
                      _buildNotificationTypeIndicator(notification),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(Color color, IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            Row(
              children: [
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildNotificationAvatar(NotificationModel notification) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getNotificationColor(notification.type),
                _getNotificationColor(notification.type).withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _getNotificationColor(notification.type).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: notification.sender?.picture != null && notification.sender!.picture!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    notification.sender!.picture!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(notification),
                  ),
                )
              : _buildDefaultAvatar(notification),
        ),
        if (!notification.read)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(NotificationModel notification) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getNotificationColor(notification.type),
            _getNotificationColor(notification.type).withOpacity(0.7),
          ],
        ),
      ),
      child: Icon(
        _getNotificationIcon(notification.type),
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildNotificationContent(NotificationModel notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: notification.read ? FontWeight.w500 : FontWeight.w600,
              height: 1.3,
            ),
            children: [
              if (notification.sender?.name != null)
                TextSpan(
                  text: '${notification.sender?.name} ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getNotificationColor(notification.type),
                  ),
                ),
              TextSpan(text: notification.content),
            ],
          ),
        ),
        if (notification.sender?.email != null) ...[
          const SizedBox(height: 4),
          Text(
            notification.sender!.email!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationMeta(NotificationModel notification) {
    final date = DateTime.parse(notification.createdAt);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays}d ago';
    } else {
      timeAgo = DateFormat('MMM d, yyyy').format(date);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getNotificationTypeLabel(notification.type),
            style: TextStyle(
              fontSize: 12,
              color: _getNotificationColor(notification.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadIndicator(NotificationModel notification) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: notification.read ? 0 : 12,
      height: notification.read ? 0 : 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF48706),
        shape: BoxShape.circle,
        boxShadow: notification.read ? null : [
          BoxShadow(
            color: const Color(0xFFF48706).withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeIndicator(NotificationModel notification) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getNotificationColor(notification.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNotificationIcon(notification.type),
        size: 16,
        color: _getNotificationColor(notification.type),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (notifications.any((n) => !n.read))
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.small(
              onPressed: markAllAsRead,
              backgroundColor: Colors.green,
              heroTag: "markAllRead",
              child: const Icon(Icons.done_all, color: Colors.white),
            ),
          ),
        const SizedBox(height: 12),
        ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              fetchNotifications();
            },
            backgroundColor: const Color(0xFFF48706),
            heroTag: "refresh",
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _getNotificationTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return 'Message';
      case 'comment':
        return 'Comment';
      case 'like':
        return 'Like';
      case 'friend_request':
        return 'Friend Request';
      case 'mention':
        return 'Mention';
      case 'share':
        return 'Share';
      case 'follow':
        return 'Follow';
      default:
        return type.toUpperCase();
    }
  }

  // [Keep all your existing navigation methods]
  void _navigateToNotificationDetails(NotificationModel notification) async {
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3066/api/v1/notifications/${notification.id}/click'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          
          if (jsonData['data'] != null && jsonData['data']['redirect'] != null) {
            final redirectData = jsonData['data']['redirect'];
            _handleRedirect(redirectData, notification);
          } else {
            _handleNotificationByType(notification);
          }
        } catch (e) {
          _handleNotificationByType(notification);
        }
      } else {
        throw Exception('Failed to handle notification click: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error handling notification: $e');
      _handleNotificationByType(notification);
    }
  }

  void _handleRedirect(Map<String, dynamic> redirectData, NotificationModel notification) {
    switch (redirectData['type']) {
      case 'content':
      case 'post':
      case 'feed':
        _navigateToSpecificFeedPost(redirectData['itemId'] ?? redirectData['contentId']);
        break;
      case 'message':
      case 'chat':
        _navigateToChat(notification);
        break;
      case 'profile':
        _navigateToProfile(redirectData['userId'] ?? redirectData['profileId']);
        break;
      default:
        _handleNotificationByType(notification);
    }
  }

  void _handleNotificationByType(NotificationModel notification) {
    switch (notification.type.toLowerCase()) {
      case 'like':
      case 'comment':
      case 'share':
      case 'mention':
        String? contentId = _extractContentIdFromNotification(notification);
        if (contentId != null) {
          _navigateToSpecificFeedPost(contentId, action: notification.type.toLowerCase());
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Homepage()),
            (route) => false,
          );
        }
        break;
      
      case 'message':
        _navigateToChat(notification);
        break;
      
      case 'friend_request':
      case 'follow':
        if (notification.sender != null) {
          _navigateToProfile(notification.sender!.id);
        }
        break;
      
      default:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => Homepage()),
          (route) => false,
        );
    }
  }

  String? _extractContentIdFromNotification(NotificationModel notification) {
    if (notification.data != null) {
      return notification.data!['contentId'] ?? 
             notification.data!['postId'] ?? 
             notification.data!['itemId'];
    }
    return null;
  }

  void _navigateToSpecificFeedPost(String contentId, {String? action}) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpecificPostScreen(
            contentId: contentId,
          ),
        ),
      );
    } catch (e) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpecificPostScreen(
            contentId: contentId,
            highlightAction: action,
          ),
        ),
      );
    }
  }

  void _navigateToChat(NotificationModel notification) {
    if (notification.sender != null) {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ChatScreen(
      //       currentUserId: AppData().currentUserId ?? '',
      //       currentUserName: AppData().currentUserName ?? '',
      //       currentUserPicture: AppData().currentUserProfilePicture ?? '',
      //       currentUserEmail: AppData().currentUserEmail ?? '',
      //       receiverId: notification.sender!.id,
      //       receiverName: notification.sender!.name ?? 'Unknown',
      //       receiverPicture: notification.sender!.picture ?? '',
      //       receiverEmail: notification.sender!.email,
      //     ),
      //   ),
      // );
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecificUserProfilePage(
          userId: userId,
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'comment':
        return Icons.mode_comment_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'friend_request':
        return Icons.person_add_outlined;
      case 'mention':
        return Icons.alternate_email;
      case 'share':
        return Icons.share_outlined;
      case 'follow':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return Colors.blue;
      case 'comment':
        return Colors.green;
      case 'like':
        return Colors.red;
      case 'friend_request':
        return Colors.purple;
      case 'mention':
        return const Color(0xFFF48706);
      case 'share':
        return Colors.teal;
      case 'follow':
        return Colors.indigo;
      default:
        return const Color(0xFFF48706);
    }
  }
}

// [Keep your existing NotificationModel and Sender classes unchanged]
class NotificationModel {
  final String id;
  final String type;
  final String content;
  final bool read;
  final String createdAt;
  final Sender? sender;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.type,
    required this.content,
    required this.read,
    required this.createdAt,
    this.sender,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      type: json['type'],
      content: json['content'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'],
      sender: json['sender'] != null ? Sender.fromJson(json['sender']) : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? content,
    bool? read,
    String? createdAt,
    Sender? sender,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      data: data ?? this.data,
    );
  }
}

class Sender {
  final String id;
  final String email;
  final String? name;
  final String? picture;

  Sender({
    required this.id,
    required this.email,
    this.name,
    this.picture,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id'],
      email: json['email'],
      name: json['name'],
      picture: json['picture'],
    );
  }
}