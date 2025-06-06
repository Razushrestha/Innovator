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
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Profile/ProfileCacheManager.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notification channel configurations
const _kHighImportanceChannelId = 'high_importance_channel';
const _kRegularChannelId = 'regular_channel';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
    _kHighImportanceChannelId,
    'High Importance Notifications',
    description: 'Critical notifications for likes, comments, and messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel regularChannel = AndroidNotificationChannel(
    _kRegularChannelId,
    'Regular Notifications',
    description: 'General app notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      await _createNotificationChannels();
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }
    } catch (e) {
      debugPrint('⚠️ Error initializing notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
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
      await Future.wait([
        androidImplementation.createNotificationChannel(highImportanceChannel),
        androidImplementation.createNotificationChannel(regularChannel),
      ]);
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation == null) return;

    final granted = await androidImplementation.requestNotificationsPermission();
    debugPrint('📱 Android notification permission granted: $granted');
    await androidImplementation.requestExactAlarmsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!);
      _handleNotificationNavigation(data);
    } catch (e) {
      debugPrint('⚠️ Error parsing notification payload: $e');
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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isHighImportance = false,
  }) async {
    debugPrint('📱 Showing notification: $title - $body');

    final channel = isHighImportance ? highImportanceChannel : regularChannel;
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: _createAndroidNotificationDetails(channel, isHighImportance),
          iOS: _createIOSNotificationDetails(isHighImportance),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('⚠️ Error showing notification: $e');
    }
  }

  AndroidNotificationDetails _createAndroidNotificationDetails(
    AndroidNotificationChannel channel,
    bool isHighImportance,
  ) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: isHighImportance ? Priority.max : Priority.high,
      ticker: 'ticker',
      color: Colors.blue,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: false,
      silent: false,
    );
  }

  DarwinNotificationDetails _createIOSNotificationDetails(bool isHighImportance) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: isHighImportance ? 'default' : null,
      badgeNumber: 1,
      subtitle: isHighImportance ? 'High Priority' : null,
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
      isHighImportance: _isHighImportanceNotification(data),
    );
  
    if (data.containsKey('click_action')) {
      _handleNotificationNavigation(data);
    }
  }

  bool _isHighImportanceNotification(Map<String, dynamic> data) {
    final notificationType = data['type']?.toString().toLowerCase() ?? '';
    return ['like', 'comment', 'message'].contains(notificationType);
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔥 Handling foreground message: ${message.messageId}');
    
    final data = message.data;
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
          await handleNotification(message);
      }
    } catch (e) {
      debugPrint('⚠️ Error handling foreground message: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] ?? data['route'] ?? data['click_action'];
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    if (screen == null && type.isEmpty) {
      debugPrint('⚠️ No navigation target specified in notification data');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateBasedOnType(type, screen, data);
    });
  }

  void _navigateBasedOnType(String type, String? screen, Map<String, dynamic> data) {
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
          _navigateBasedOnScreen(screen.toLowerCase(), data);
        }
    }
  }

  void _navigateBasedOnScreen(String screen, Map<String, dynamic> data) {
    switch (screen) {
      case 'chat':
        Get.toNamed('/chat', arguments: data);
        break;
      case 'profile':
        Get.toNamed('/profile', arguments: data);
        break;
      case 'home':
      default:
        Get.offAllNamed('/home', arguments: data);
    }
  }

  Future<bool> sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? click_action,
  }) async {
    try {
      return await FCMHandler.sendToUser(
        userId,
        title: title,
        body: body,
        type: type,
        screen: screen,
        data: data,
        click_action: click_action,
      );
    } catch (e) {
      debugPrint('⚠️ Error sending FCM notification: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔥 FCM Background Message: ${message.messageId}');
    
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.handleNotification(message);
  } catch (e) {
    debugPrint('⚠️ Error handling background message: $e');
  }
}

Future<void> _initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final notificationService = NotificationService();
    await notificationService.initialize();
    
    final appData = AppData();
    await appData.initialize();
    await appData.initializeFcm();
    
    await _setupFirebaseMessaging(notificationService);
    await _configureSystemUI();
    
    // Initialize UserController
    Get.put(UserController());
    
    debugPrint('🚀 App initialization completed');
  } catch (e) {
    debugPrint('⚠️ Error during app initialization: $e');
    rethrow;
  }
}

Future<void> _setupFirebaseMessaging(NotificationService notificationService) async {
  final messaging = FirebaseMessaging.instance;
  
  // Initialize FCMHandler with your server key
  FCMHandler.initialize('YOUR_FIREBASE_SERVER_KEY'); // Replace with your actual server key
  
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  // Get the FCM token
  final token = await messaging.getToken();
  debugPrint('📱 FCM Token: $token');

  // Handle different message scenarios
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('📱 FCM Foreground Message: ${message.messageId}');
    notificationService.handleForegroundMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('📱 FCM Message Opened App: ${message.messageId}');
    notificationService.handleNotification(message);
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('📱 Initial message found: ${initialMessage.messageId}');
    notificationService.handleNotification(initialMessage);
  }
}

Future<void> _configureSystemUI() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void main() async {
  await _initializeApp();
  //await ProfileCacheManager.initialize();
  await DrawerProfileCache.initialize();

   await CacheManager.initialize();

  runApp(const ProviderScope(child: InnovatorHomePage()));
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _setupPeriodicNotificationFetch();
  }

  void _setupPeriodicNotificationFetch() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async => await AppData().fetchNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mq = MediaQuery.of(context).size;
    });

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      getPages: _buildAppPages(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
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
    );
  }

  List<GetPage> _buildAppPages() {
    return [
      GetPage(name: '/splash', page: () => const SplashScreen()),
      GetPage(name: '/home', page: () => const HomeScreen()),
      GetPage(name: '/chat', page: () => const ChatScreen()),
      GetPage(name: '/profile', page: () => const ProfileScreen()),
      GetPage(name: '/orders', page: () => const OrdersScreen()),
    ];
  }
}

// Screen Widgets
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(
      body: Center(
        child: Text('Home Screen: ${args ?? ''}'),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(
      body: Center(
        child: Text('Chat Screen: ${args ?? ''}'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(
      body: Center(
        child: Text('Profile Screen: ${args ?? ''}'),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    return Scaffold(
      body: Center(
        child: Text('Orders Screen: ${args ?? ''}'),
      ),
    );
  }
}