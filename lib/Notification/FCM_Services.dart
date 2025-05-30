import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/innovator_home.dart';
import 'package:intl/intl.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<NotificationModel> notifications = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextCursor;
  bool hasMore = true;
  bool isDeletingAll = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> fetchNotifications() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse('http://182.93.94.210:3064/api/v1/notifications');
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
          'http://182.93.94.210:3064/api/v1/notifications?cursor=$nextCursor');
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
        Uri.parse('http://182.93.94.210:3064/api/v1/notifications/mark-read'),
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
        Uri.parse('http://182.93.94.210:3064/api/v1/notifications/mark-all-read'),
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
        Uri.parse('http://182.93.94.210:3064/api/v1/notifications/$notificationId'),
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
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeletingAll = true);
    try {
      final token = AppData().authToken;
      if (token == null) throw Exception('No authentication token found');

      final response = await http.delete(
        Uri.parse('http://182.93.94.210:3064/api/v1/notifications'),
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Homepage())),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: markAllAsRead,
              tooltip: 'Mark all as read',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'delete_all') {
                  deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Delete all notifications'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            TextButton(
              onPressed: fetchNotifications,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchNotifications,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notifications.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return _buildLoadMoreIndicator();
          }
          return _buildNotificationItem(notifications[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoadingMore
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: fetchMoreNotifications,
                child: const Text('Load more notifications'),
              ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
      },
      onDismissed: (_) => deleteNotification(notification.id),
      child: InkWell(
        onTap: () {
          if (!notification.read) {
            markAsRead(notification.id);
          }
          _navigateToNotificationDetails(notification);
        },
        child: Container(
          color: notification.read ? Colors.white : Colors.blue[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationContent(notification),
                    _buildNotificationMeta(notification),
                  ],
                ),
              ),
              _buildUnreadIndicator(notification),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getNotificationColor(notification.type),
      ),
      child: Icon(
        _getNotificationIcon(notification.type),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationContent(NotificationModel notification) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
        children: [
          if (notification.sender?.name != null)
            TextSpan(
              text: '${notification.sender?.name} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          TextSpan(text: notification.content),
        ],
      ),
    );
  }

  Widget _buildNotificationMeta(NotificationModel notification) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              DateFormat('MMM d, yyyy • HH:mm').format(DateTime.parse(notification.createdAt)),
              style: const TextStyle(fontSize: 8, color: Colors.grey),
            ),
             if (notification.sender?.email != null) ...[
                          const Text(' • ', style: TextStyle(color: Colors.grey)),
                          Text(
            notification.sender!.email!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
           
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadIndicator(NotificationModel notification) {
    return !notification.read
        ? Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          )
        : const SizedBox(width: 8);
  }

  void _navigateToNotificationDetails(NotificationModel notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: RemoteMessage(
            data: {
              'type': notification.type,
              'content': notification.content,
              'sender': notification.sender?.name ?? 'Unknown',
              'createdAt': notification.createdAt,
            },
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return Icons.message;
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'friend_request':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
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
        return Colors.orange;
      default:
        return Colors.deepOrange;
    }
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final RemoteMessage notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationHeader(),
            const SizedBox(height: 24),
            _buildNotificationContent(),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildAdditionalData(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getNotificationColor(notification.data['type'] ?? ''),
          ),
          child: Icon(
            _getNotificationIcon(notification.data['type'] ?? ''),
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.data['type']?.toString().toUpperCase() ?? 'NOTIFICATION',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'From: ${notification.data['sender'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM d, yyyy • HH:mm').format(
                  DateTime.parse(notification.data['createdAt'] ?? DateTime.now().toString()),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationContent() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          notification.data['content'] ?? 'No content available',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAdditionalData() {
    final additionalData = notification.data.entries
        .where((entry) => !['type', 'content', 'sender', 'createdAt'].contains(entry.key))
        .toList();

    if (additionalData.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: additionalData
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return Icons.message;
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'friend_request':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
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
        return Colors.orange;
      default:
        return Colors.deepOrange;
    }
  }
}

class NotificationModel {
  final String id;
  final String type;
  final String content;
  final bool read;
  final String createdAt;
  final Sender? sender;

  NotificationModel({
    required this.id,
    required this.type,
    required this.content,
    required this.read,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      type: json['type'],
      content: json['content'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'],
      sender: json['sender'] != null ? Sender.fromJson(json['sender']) : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? content,
    bool? read,
    String? createdAt,
    Sender? sender,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
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