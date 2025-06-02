import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

class FCMNotificationService {
  static final FCMNotificationService _instance = FCMNotificationService._internal();
  factory FCMNotificationService() => _instance;
  FCMNotificationService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidNotificationChannel channel;
  bool isFlutterLocalNotificationsInitialized = false;

  final StreamController<NotificationResponse> _notificationStreamController = 
      StreamController<NotificationResponse>.broadcast();

  Stream<NotificationResponse> get notificationStream => _notificationStreamController.stream;

  Future<void> initialize() async {
    try {
      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      developer.log('✅ FCM Notification Service initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing FCM Notification Service: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Enable FCM
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      
      // Request permissions (especially important for iOS)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      
      developer.log('FCM Permission Status: ${settings.authorizationStatus}');

      // Get FCM token and save it using AppData
      await _handleFCMToken();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        developer.log('🔄 FCM Token refreshed: $newToken');
        await _saveFCMTokenToAppData(newToken);
        await _registerTokenWithServer(newToken);
      });

      // Handle foreground messages (INSTANT notifications)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('🔥 INSTANT FCM Foreground Message Received!');
        developer.log('Title: ${message.notification?.title}');
        developer.log('Body: ${message.notification?.body}');
        developer.log('Data: ${message.data}');

        _showInstantNotification(
          title: message.notification?.title ?? 'New Message',
          body: message.notification?.body ?? 'You have a new notification',
          data: message.data,
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        );
      });

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('📱 App opened from FCM notification');
        _handleNotificationTap(message.data);
      });

      // Check if app was launched from a notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        developer.log('🚀 App launched from FCM notification');
        // Handle the initial notification after a small delay
        Future.delayed(Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage.data);
        });
      }

      developer.log('✅ Firebase Messaging setup completed');
    } catch (e) {
      developer.log('❌ Error setting up Firebase Messaging: $e');
    }
  }

  // Handle FCM token retrieval and storage
  Future<void> _handleFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken(
        vapidKey: null, // Add your VAPID key here if using web
      );
      
      if (token != null) {
        developer.log('🔑 FCM Token retrieved: $token');
        await _saveFCMTokenToAppData(token);
        await _registerTokenWithServer(token);
      } else {
        developer.log('❌ Failed to retrieve FCM token');
      }
    } catch (e) {
      developer.log('❌ Error handling FCM token: $e');
    }
  }

  // Save FCM token to AppData
  Future<void> _saveFCMTokenToAppData(String token) async {
    try {
      await AppData().saveFcmToken(token);
      developer.log('✅ FCM token saved to AppData successfully');
      
      // Log current FCM tokens for debugging
      final currentTokens = AppData().fcmTokens;
      developer.log('📋 Current FCM tokens in AppData: $currentTokens');
    } catch (e) {
      developer.log('❌ Error saving FCM token to AppData: $e');
    }
  }

  // Register FCM token with your backend server
  Future<void> _registerTokenWithServer(String token) async {
    try {
      final authToken = AppData().authToken;
      final userId = AppData().currentUserId;
      
      if (authToken == null || userId == null) {
        developer.log('❌ Cannot register FCM token: Missing auth token or user ID');
        return;
      }

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/fcm/register'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': token,
          'device_type': 'mobile',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ FCM token registered successfully with server');
        developer.log('Server response: ${response.body}');
      } else {
        developer.log('❌ Failed to register FCM token with server: ${response.statusCode}');
        developer.log('Error response: ${response.body}');
      }
    } catch (e) {
      developer.log('❌ Error registering FCM token with server: $e');
    }
  }

  // Method to refresh and update FCM token manually
  Future<void> refreshFCMToken() async {
    try {
      developer.log('🔄 Manually refreshing FCM token...');
      await FirebaseMessaging.instance.deleteToken();
      await _handleFCMToken();
    } catch (e) {
      developer.log('❌ Error refreshing FCM token: $e');
    }
  }

  // Method to get current FCM token from AppData
  String? getCurrentFCMTokenFromAppData() {
    final tokens = AppData().fcmTokens;
    if (tokens != null && tokens.isNotEmpty) {
      developer.log('📱 Current FCM token from AppData: ${tokens.last}');
      return tokens.last; // Return the most recent token
    }
    developer.log('❌ No FCM token found in AppData');
    return null;
  }

  Future<void> _setupLocalNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
      requestProvisionalPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        developer.log('iOS local notification received: $title');
        _notificationStreamController.add(
          NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotification,
            id: id,
            actionId: null,
            input: null,
            payload: payload,
          ),
        );
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Local notification tapped: ${response.payload}');
        _notificationStreamController.add(response);
      },
    );

    developer.log('Local notifications initialized: $initialized');

    // Create high-priority notification channel for Android
    channel = const AndroidNotificationChannel(
      'fcm_instant_channel',
      'Instant FCM Notifications',
      description: 'Channel for instant Firebase Cloud Messaging notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      developer.log('✅ Android notification channel created');
    }

    isFlutterLocalNotificationsInitialized = true;
    _configureLocalTimeZone();
  }

  void _configureLocalTimeZone() {
    tz.initializeTimeZones();
    final local = tz.local;
    developer.log('Timezone configured: ${local.name}');
  }

  // Show instant notification for FCM messages
  Future<void> _showInstantNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    if (!isFlutterLocalNotificationsInitialized) {
      developer.log('❌ Local notifications not initialized');
      return;
    }

    try {
      final now = DateTime.now();
      final notificationId = now.millisecondsSinceEpoch % 100000;

      // Android notification details
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'fcm_instant_channel',
        'Instant FCM Notifications',
        channelDescription: 'Channel for instant Firebase Cloud Messaging notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'New instant message',
        showWhen: true,
        when: now.millisecondsSinceEpoch,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'), // Custom sound
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        ),
        autoCancel: true,
        ongoing: false,
        category: AndroidNotificationCategory.message,
        fullScreenIntent: data['urgent'] == 'true', // Full screen for urgent notifications
      );

      // Add image if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        androidNotificationDetails = AndroidNotificationDetails(
          'fcm_instant_channel',
          'Instant FCM Notifications',
          channelDescription: 'Channel for instant Firebase Cloud Messaging notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'New instant message',
          showWhen: true,
          when: now.millisecondsSinceEpoch,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(imageUrl),
            contentTitle: title,
            htmlFormatContentTitle: true,
            summaryText: body,
            htmlFormatSummaryText: true,
          ),
          autoCancel: true,
          ongoing: false,
          category: AndroidNotificationCategory.message,
        );
      }

      // iOS notification details
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'fcm_notifications',
        categoryIdentifier: 'message_category',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      developer.log('🔔 Instant notification shown: $title');
    } catch (e) {
      developer.log('❌ Error showing instant notification: $e');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    developer.log('📱 Notification tapped with data: $data');
    
    // Add your navigation logic here based on the data
    if (data.containsKey('screen')) {
      // Navigate to specific screen
      String screen = data['screen'];
      switch (screen) {
        case 'chat':
          // Navigate to chat screen
          break;
        case 'profile':
          // Navigate to profile screen
          break;
        case 'orders':
          // Navigate to orders screen
          break;
        default:
          // Navigate to home screen
          break;
      }
    }
    
    // You can also use your existing navigation logic here
    // navigatorKey.currentState?.pushNamed(data['route'] ?? '/home');
  }

  // Method to subscribe to specific topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      developer.log('✅ Subscribed to topic: $topic');
    } catch (e) {
      developer.log('❌ Error subscribing to topic $topic: $e');
    }
  }

  // Method to unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      developer.log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  // Get current FCM token from Firebase
  Future<String?> getCurrentToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      developer.log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    developer.log('🗑️ All notifications cleared');
  }

  // Clear specific notification
  Future<void> clearNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    developer.log('🗑️ Notification $id cleared');
  }

  // Method to sync FCM token with server when user logs in
  Future<void> syncFCMTokenOnLogin() async {
    try {
      developer.log('🔄 Syncing FCM token after login...');
      
      // Get current token from Firebase
      String? currentToken = await getCurrentToken();
      if (currentToken != null) {
        await _saveFCMTokenToAppData(currentToken);
        await _registerTokenWithServer(currentToken);
      }
      
      // Also get token from AppData if available
      String? appDataToken = getCurrentFCMTokenFromAppData();
      if (appDataToken != null && appDataToken != currentToken) {
        await _registerTokenWithServer(appDataToken);
      }
    } catch (e) {
      developer.log('❌ Error syncing FCM token on login: $e');
    }
  }

  Future<void> dispose() async {
    await _notificationStreamController.close();
    developer.log('🔄 FCM Notification Service disposed');
  }
}

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('🔥 FCM Background Message: ${message.messageId}');
  developer.log('Title: ${message.notification?.title}');
  developer.log('Body: ${message.notification?.body}');
  developer.log('Data: ${message.data}');
  
  // Background notifications are automatically shown by FCM
  // No need to manually show notification here
}