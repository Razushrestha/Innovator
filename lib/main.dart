import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';

// Notification Service class
// Enhanced NotificationService for better reliability
late Size mq;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // High importance channel for critical notifications
  static const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Critical notifications for likes, comments, and messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Regular channel for other notifications
  static const AndroidNotificationChannel regularChannel = AndroidNotificationChannel(
    'regular_channel',
    'Regular Notifications',
    description: 'General app notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Android initialization with enhanced settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization with all permissions
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // For critical alerts
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
    
    // Request Android 13+ notification permission
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(highImportanceChannel);
        await androidImplementation.createNotificationChannel(regularChannel);
      }
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    final granted = await androidImplementation?.requestNotificationsPermission();
    print('Android notification permission granted: $granted');
    
    // Request exact alarm permission for scheduled notifications
    await androidImplementation?.requestExactAlarmsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Enhanced notification display for likes and comments
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
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Comment! 💬',
      body: '$userName commented: ${comment.length > 50 ? comment.substring(0, 50) + '...' : comment}',
      payload: jsonEncode(data ?? {'type': 'comment', 'screen': 'home'}),
      isHighImportance: true,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isHighImportance = false,
  }) async {
    print('📱 Showing notification: $title - $body');

    final channel = isHighImportance ? highImportanceChannel : regularChannel;
    
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
          ticker: title,
          color: Colors.blue,
          enableVibration: true,
          playSound: true,
          // Enhanced settings for better visibility
          visibility: NotificationVisibility.public,
          autoCancel: true,
          ongoing: false,
          silent: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: isHighImportance ? 'default' : null,
          badgeNumber: 1,
          subtitle: isHighImportance ? 'High Priority' : null,
        ),
      ),
      payload: payload,
    );
  }
  Future<void> handleNotification(RemoteMessage message) async {
  final data = message.data;
  final notification = message.notification;
  
  await showNotification(
    id: message.hashCode,
    title: notification?.title ?? 'New Notification',
    body: notification?.body ?? 'You have a new notification',
    payload: jsonEncode(data),
  );
  
  if (data.containsKey('click_action')) {
    _handleNotificationNavigation(data);
  }
}

  // Enhanced foreground message handling
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    print('🔥 Handling foreground message: ${message.messageId}');
    
    final data = message.data;
    final notification = message.notification;
    
    // Determine if it's a like or comment notification
    final notificationType = data['type'] ?? '';
    final isHighImportance = ['like', 'comment', 'message'].contains(notificationType);
    
    if (notificationType == 'like') {
      await showLikeNotification(
        userName: data['userName'] ?? 'Someone',
        postTitle: data['postTitle'] ?? 'your post',
        data: data,
      );
    } else if (notificationType == 'comment') {
      await showCommentNotification(
        userName: data['userName'] ?? 'Someone',
        comment: data['comment'] ?? 'commented on your post',
        postTitle: data['postTitle'] ?? 'your post',
        data: data,
      );
    } else {
      // Generic notification
      await showNotification(
        id: message.hashCode,
        title: notification?.title ?? 'New Notification',
        body: notification?.body ?? 'You have a new notification',
        payload: jsonEncode(data),
        isHighImportance: isHighImportance,
      );
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] ?? data['route'] ?? data['click_action'];
    final type = data['type'] ?? '';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (type.toLowerCase()) {
        case 'like':
        case 'comment':
          Get.toNamed('/home', arguments: data);
          break;
        case 'message':
          Get.toNamed('/chat', arguments: data);
          break;
        default:
          if (screen != null) {
            switch (screen.toLowerCase()) {
              case 'chat':
                Get.toNamed('/chat', arguments: data);
                break;
              case 'profile':
                Get.toNamed('/profile', arguments: data);
                break;
              case 'home':
              default:
                Get.offAllNamed('/home', arguments: data);
                break;
            }
          }
          break;
      }
    });
  }
}
// Global variables
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔥 FCM Background Message Received');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.handleNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp();
  
  // Set background message handler BEFORE any other Firebase operations
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();
  final appData = AppData();
  await appData.initialize();
  await appData.initializeFcm();
  
  // Request permissions
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // FIXED: Set up message listeners properly
  // Handle foreground messages
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   debugPrint('📱 FCM Foreground Message Received: ${message.messageId}');
  //   notificationService.handleForegroundMessage(message);
  // });
  // final initialMessage = await messaging.getInitialMessage();
  // if (initialMessage != null) {
  //   debugPrint('📱 FCM Initial Message: ${initialMessage.messageId}');
  //   // Handle after app is fully loaded
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     notificationService.handleTerminatedMessage(initialMessage);
  //   });
  // }
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📱 FCM Foreground Message: ${message.messageId}');
    notificationService.handleForegroundMessage(message);
  });
  
  // Handle background/opened messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📱 FCM Message Opened App: ${message.messageId}');
    notificationService.handleNotification(message);
  });
  
  
  // Handle terminated state messages
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('📱 Initial message found: ${initialMessage.messageId}');
    notificationService.handleNotification(initialMessage);
  }
  // Initialize app data

  await AppData().initialize();
  await AppData().initializeFcm();

  // Set system UI preferences
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('🚀 App initialization completed');

  runApp(ProviderScope(child: InnovatorHomePage()));
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  final notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    // REMOVED: Duplicate listeners that were causing conflicts
    // The listeners are now set up in main() function

    // Periodically fetch notifications from API
    Timer.periodic(Duration(minutes: 5), (timer) async {
      await AppData().fetchNotifications();
    });

    debugPrint('📱 App started and listening for notifications');
  }

  void _handleMessageNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] ?? data['route'] ?? data['click_action'];
    if (screen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (screen.toLowerCase()) {
          case 'chat':
            Get.toNamed('/chat', arguments: data);
            break;
          case 'profile':
            Get.toNamed('/profile', arguments: data);
            break;
          case 'orders':
            Get.toNamed('/orders', arguments: data);
            break;
          case 'home':
          default:
            Get.offAllNamed('/home', arguments: data);
            break;
        }
      });
    } else {
      debugPrint('⚠️ No screen or route specified in notification data');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set mq after context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mq = MediaQuery.of(context).size;
    });

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Inovator',
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 19,
          ),
          backgroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/chat', page: () => const ChatScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/orders', page: () => const OrdersScreen()),
      ],
    );
  }
}

// Placeholder screens (replace with your actual implementations)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(body: Center(child: Text('Home Screen: ${args ?? ''}')));
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(body: Center(child: Text('Chat Screen: ${args ?? ''}')));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(body: Center(child: Text('Profile Screen: ${args ?? ''}')));
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(body: Center(child: Text('Orders Screen: ${args ?? ''}')));
  }
}