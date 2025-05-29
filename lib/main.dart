import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

late Size mq;

// Global navigation key to access navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FCMService.showNotificationStatic(message);
    developer.log('Background notification shown successfully');
  } catch (e) {
    developer.log('Error showing background notification: $e');
  }
  developer.log('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppData().initialize();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM service
  await FCMService.initialize();
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      child: InnovatorHomePage(),
    ),
  );
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _setupFCMListeners();
    developer.log('Current user data on InnovatorHomePage init: ${AppData().currentUser}');
    developer.log('Current fcmTokens: ${AppData().fcmTokens}');
  }

  Future<void> _requestNotificationPermission() async {
    try {
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        developer.log('Notification permission status: $status');
        if (status.isDenied) {
          if (await Permission.notification.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      }

      // Request FCM permission
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        provisional: false,
      );
      developer.log('FCM permission status: ${settings.authorizationStatus}');
      
      await FCMService.checkAndRequestBatteryOptimization(context);

      if (Platform.isAndroid) {
        developer.log('Running on Android, please ensure battery optimization is disabled for Innovator');
      }
    } catch (e) {
      developer.log('Error requesting notification permission: $e');
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
        setState(() {
          _unreadCount = data['data']['unreadCount'] ?? 0;
          _notifications = (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        });
      } else {
        developer.log('Failed to load notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error loading notifications: $e');
    }
  }

  void _setupFCMListeners() {
    // This will now be handled globally by FCMService
    // but we can still listen here for UI updates
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received in main widget: ${message.messageId}');
      // Refresh notifications count if needed
      // _loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return GetMaterialApp(
      navigatorKey: navigatorKey, // Add global navigator key
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
      home: Scaffold(
        body: const SplashScreen(),
      ),
    );
  }
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> checkAndRequestBatteryOptimization(BuildContext? context) async {
    if (Platform.isAndroid && context != null) {
      try {
        const MethodChannel platform = MethodChannel('battery_optimization');
        
        bool isIgnoringBatteryOptimizations = await platform.invokeMethod('isIgnoringBatteryOptimizations');
        
        if (!isIgnoringBatteryOptimizations) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Battery Optimization'),
              content: Text(
                'To receive notifications when the app is closed, please disable battery optimization for this app.\n\n'
                'This will not significantly impact your battery life.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await platform.invokeMethod('requestIgnoreBatteryOptimizations');
                  },
                  child: Text('Settings'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        developer.log('Error checking battery optimization: $e');
      }
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('FCMService already initialized');
      return;
    }

    try {
      // Create notification channel FIRST
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Channel for important notifications',
        importance: Importance.max,
        playSound: true,
        showBadge: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);

        // Request exact alarm permission for Android 12+
        if (Platform.isAndroid) {
          await androidPlugin.requestExactAlarmsPermission();
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload != null) {
            developer.log('Notification tapped with payload: $payload');
            _handleNotificationTap(payload);
          }
        },
      );

      // Request FCM permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      developer.log('FCM permission status: ${settings.authorizationStatus}');

      // Set up global message listeners
      _setupGlobalMessageListeners();

      // Get and save FCM token
      await _updateFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        developer.log('FCM token refreshed: $newToken');
        AppData().saveFcmToken(newToken);
        _updateTokenOnServer(newToken);
      });

      _isInitialized = true;
      developer.log('FCMService initialized successfully');

    } catch (e) {
      developer.log('Error initializing FCM: $e');
    }
  }

  static void _setupGlobalMessageListeners() {
    // Handle foreground messages - these will show on ANY screen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received globally: ${message.messageId}');
      showNotification(message);
    });

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Message opened app globally: ${message.messageId}');
      _navigateToNotificationScreen(message);
    });

    // Handle initial message when app is opened from notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('App opened from notification: ${message.messageId}');
        // Delay navigation to ensure app is fully loaded
        Future.delayed(Duration(seconds: 2), () {
          _navigateToNotificationScreen(message);
        });
      }
    });
  }

  static void _handleNotificationTap(String payload) {
    try {
      final data = json.decode(payload);
      final message = RemoteMessage(data: Map<String, String>.from(data));
      _navigateToNotificationScreen(message);
    } catch (e) {
      developer.log('Error handling notification tap: $e');
    }
  }

  static void _navigateToNotificationScreen(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(notification: message),
        ),
      );
    } else {
      developer.log('Navigator context not available');
    }
  }

  static Future<void> showNotificationStatic(RemoteMessage message) async {
    try {
      // Initialize local notifications plugin for background use
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
      await localNotifications.initialize(initializationSettings);

      // Create notification channel for background
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      await _showNotificationInternal(message, localNotifications);
    } catch (e) {
      developer.log('Error showing background notification: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    await _showNotificationInternal(message, _notificationsPlugin);
  }

  static Future<void> _showNotificationInternal(
    RemoteMessage message, 
    FlutterLocalNotificationsPlugin plugin
  ) async {
    try {
      developer.log('Processing notification: ${message.messageId}');
      final notification = message.notification;
      final data = message.data;

      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/launcher_icon',
        color: const Color(0xFF4A90E2),
        showWhen: true,
        enableVibration: true,
        channelShowBadge: true,
        autoCancel: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        ticker: 'New notification received',
        when: DateTime.now().millisecondsSinceEpoch,
        usesChronometer: false,
        onlyAlertOnce: false,
        ongoing: false,
        silent: false,
        // Add these for better visibility
        styleInformation: BigTextStyleInformation(
          notification?.body ?? data['body'] ?? 'You have a new notification',
          contentTitle: notification?.title ?? data['title'] ?? 'New Notification',
          summaryText: 'Innovator App',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'general',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await plugin.show(
        notificationId,
        notification?.title ?? data['title'] ?? 'New Notification',
        notification?.body ?? data['body'] ?? 'You have a new notification',
        notificationDetails,
        payload: json.encode(data),
      );
      
      developer.log('Notification shown successfully: ${message.messageId}');
    } catch (e, stackTrace) {
      developer.log('Error showing notification: $e', stackTrace: stackTrace);
    }
  }

  static Future<void> _updateFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await AppData().saveFcmToken(token);
        developer.log('FCM token saved: $token');
        await _updateTokenOnServer(token);
      } else {
        developer.log('Failed to retrieve FCM token');
      }
    } catch (e) {
      developer.log('Error updating FCM token: $e');
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      final userId = AppData().currentUser?['_id'] ?? '';
      if (userId.isEmpty) {
        developer.log('User ID not found, skipping FCM token update');
        return;
      }

      final response = await http.post(
        Uri.parse('http://182.93.94.210:3064/api/v1/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppData().authToken}',
        },
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        developer.log('FCM token updated on backend: ${response.body}');
      } else {
        developer.log('Failed to update FCM token on backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error updating FCM token on server: $e');
    }
  }

  // Method to ensure FCM is working on any screen
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}

// Rest of your existing classes remain the same
class NotificationListScreen extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationListScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications', style: TextStyle(backgroundColor: Colors.orange)),
        leading: IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => Homepage()));
          }, 
          icon: Icon(Icons.arrow_back)
        ),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification.content),
            subtitle: Text(
              'From: ${notification.sender?.email ?? 'Unknown'} • ${notification.createdAt}',
            ),
            trailing: notification.read ? null : const Icon(Icons.brightness_1, size: 12, color: Colors.blue),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                    notification: RemoteMessage(
                      data: {
                        'type': notification.type,
                        'content': notification.content,
                        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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

class NotificationScreen extends StatelessWidget {
  final RemoteMessage notification;

  const NotificationScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.notification?.title ?? notification.data['title'] ?? 'Notification',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              notification.notification?.body ??
                  notification.data['body'] ??
                  notification.data['content'] ??
                  'No content available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text('Additional Data:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...notification.data.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
          ],
        ),
      ),
    );
  }
}

// Mixin to ensure FCM works on any screen
mixin FCMEnabledScreen<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    FCMService.ensureInitialized();
  }
}

// Example of how to use the mixin in any screen
class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> with FCMEnabledScreen {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Example Screen')),
      body: Center(
        child: Text('Notifications will work on this screen too!'),
      ),
    );
  }
}