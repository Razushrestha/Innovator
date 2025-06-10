import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Critical notifications for likes, comments, and messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel regularChannel = AndroidNotificationChannel(
    'regular_channel',
    'Regular Notifications',
    description: 'General app notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing NotificationService...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create notification channels for Android
      await _createNotificationChannels();
      
      // Request permissions
      await _requestPermissions();
      
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(highImportanceChannel);
      await androidImplementation.createNotificationChannel(regularChannel);
      debugPrint('📱 Android notification channels created');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('📱 Android notification permission: $granted');
        
        // Request exact alarms permission for Android 12+
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
    
    // Firebase messaging permissions
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔥 Firebase messaging permission: ${settings.authorizationStatus}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!);
      _handleNotificationNavigation(data);
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isHighImportance = false,
  }) async {
    debugPrint('🔔 Showing notification - ID: $id, Title: $title, Body: $body');

    final channel = isHighImportance ? highImportanceChannel : regularChannel;
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: isHighImportance ? Priority.max : Priority.high,
            color: Colors.blue,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        payload: payload,
      );
      debugPrint('✅ Notification shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  Future<void> showLikeNotification({
    required String userName,
    required String postTitle,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Like! 👍',
      body: '$userName liked your post: $postTitle',
      payload: jsonEncode(data ?? {'type': 'like', 'screen': 'home'}),
      isHighImportance: true,
    );
  }

  Future<void> showCommentNotification({
    required String userName,
    required String comment,
    required String postTitle,
    Map<String, dynamic>? data,
  }) async {
    final truncatedComment = comment.length > 50 
        ? '${comment.substring(0, 47)}...' 
        : comment;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Comment! 💬',
      body: '$userName commented: $truncatedComment',
      payload: jsonEncode(data ?? {'type': 'comment', 'screen': 'home'}),
      isHighImportance: true,
    );
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔥 Handling foreground message: ${message.messageId}');
    debugPrint('🔥 Message data: ${message.data}');
    debugPrint('🔥 Message notification: ${message.notification?.title} - ${message.notification?.body}');
    
    final data = message.data;
    final notification = message.notification;
    final notificationType = data['type']?.toString().toLowerCase() ?? '';
    
    try {
      switch (notificationType) {
        case 'like':
          await showLikeNotification(
            userName: data['userName'] ?? 'Someone',
            postTitle: data['postTitle'] ?? 'your post',
            data: data,
          );
          break;
        case 'comment':
          await showCommentNotification(
            userName: data['userName'] ?? 'Someone',
            comment: data['comment'] ?? 'commented on your post',
            postTitle: data['postTitle'] ?? 'your post',
            data: data,
          );
          break;
        default:
          // Show generic notification
          await showNotification(
            id: message.hashCode,
            title: notification?.title ?? 'New Notification',
            body: notification?.body ?? 'You have a new notification',
            payload: jsonEncode(data),
            isHighImportance: _isHighImportanceNotification(data),
          );
      }
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }

  bool _isHighImportanceNotification(Map<String, dynamic> data) {
    final notificationType = data['type']?.toString().toLowerCase() ?? '';
    return ['like', 'comment', 'message'].contains(notificationType);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] ?? data['route'] ?? data['click_action'];
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    debugPrint('🔔 Navigating - Type: $type, Screen: $screen');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (type) {
        case 'like':
        case 'comment':
          Get.toNamed('/home', arguments: data);
          break;
        case 'message':
          Get.toNamed('/chat', arguments: data);
          break;
        default:
          if (screen != null) {
            _navigateToScreen(screen.toString().toLowerCase(), data);
          }
      }
    });
  }

  void _navigateToScreen(String screen, Map<String, dynamic> data) {
    switch (screen) {
      case 'chat':
        Get.toNamed('/chat', arguments: data);
        break;
      case 'profile':
        Get.toNamed('/profile', arguments: data);
        break;
      case 'home':
      default:
        Get.toNamed('/home', arguments: data);
    }
  }

  // Test notification method
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working',
      isHighImportance: true,
    );
  }
}