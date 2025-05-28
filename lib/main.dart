import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Eliza_ChatBot/global.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

late Size mq;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService.showNotification(message);
  await FCMService.initialize();
  developer.log('Handling background message: ${message.messageId}');
}
 
void main() async {
  //Gemini.init(apiKey: api_key);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppData().initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
   // _loadNotifications();
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
        // Prompt user to enable notifications manually
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
    );
    developer.log('FCM permission status: ${settings.authorizationStatus}');

    // MIUI-specific: Check if battery optimization is enabled
    if (Platform.isAndroid) {
      // Note: Requires additional package like `device_info_plus` to detect MIUI
      developer.log('Running on Android, please ensure battery optimization is disabled for Innovator');
      // Optionally, guide user to disable battery optimization (manual step for now)
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received: ${message.messageId}');
      FCMService.showNotification(message);
      //_loadNotifications();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Message opened app: ${message.messageId}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(notification: message),
        ),
      );
      //_loadNotifications();
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('Initial message: ${message.messageId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationScreen(notification: message),
          ),
        );
        _loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return GetMaterialApp(
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
        // appBar: AppBar(
        //   title: const Text('Inovator'),
        //   actions: [
        //     Stack(
        //       children: [
        //         IconButton(
        //           icon: const Icon(Icons.notifications),
        //           onPressed: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (context) => NotificationListScreen(notifications: _notifications),
        //               ),
        //             );
        //           },
        //         ),
        //         if (_unreadCount > 0)
        //           Positioned(
        //             right: 8,
        //             top: 8,
        //             child: Container(
        //               padding: const EdgeInsets.all(2),
        //               decoration: BoxDecoration(
        //                 color: Colors.red,
        //                 borderRadius: BorderRadius.circular(10),
        //               ),
        //               constraints: const BoxConstraints(
        //                 minWidth: 16,
        //                 minHeight: 16,
        //               ),
        //               child: Text(
        //                 '$_unreadCount',
        //                 style: const TextStyle(
        //                   color: Colors.white,
        //                   fontSize: 10,
        //                 ),
        //                 textAlign: TextAlign.center,
        //               ),
        //             ),
        //           ),
        //       ],
        //     ),
        //   ],
        // ),
        body: const SplashScreen(), // Replace with your actual home screen
      ),
    );
  }
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Create notification channel FIRST
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'Channel for default notifications',
        importance: Importance.max,
        playSound: true,
        showBadge: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
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
            // Handle notification tap
          }
        },
      );

      // Request permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log('FCM permission status: ${settings.authorizationStatus}');

      // Handle foreground messages only here
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Foreground message received: ${message.messageId}');
        showNotification(message);
      });

      // Get and save FCM token
      await _updateFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        developer.log('FCM token refreshed: $newToken');
        AppData().saveFcmToken(newToken);
        _updateTokenOnServer(newToken);
      });

    } catch (e) {
      developer.log('Error initializing FCM: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    try {
      developer.log('Processing notification: ${message.messageId}');
      final notification = message.notification;
      final data = message.data;

      // Create a unique notification ID
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'Channel for default notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/launcher_icon',
        color: const Color(0xFF4A90E2),
        showWhen: true,
        enableVibration: true,
        channelShowBadge: true,
        autoCancel: true,
        fullScreenIntent: true, // For heads-up notification
      );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
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
}
class NotificationListScreen extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationListScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('All Notifications', style: TextStyle(backgroundColor: Colors.orange),),
leading: 
  IconButton(onPressed: (){
  Navigator.push(context, MaterialPageRoute(builder: (_) => Homepage()));
}, icon: Icon(Icons.arrow_back)),
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

// Placeholder for SplashScreen
// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: CircularProgressIndicator());
//   }
// }