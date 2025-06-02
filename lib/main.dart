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
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';

import 'Notification/FCM_Class.dart'; // Updated import

late Size mq;

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  debugPrint('🔥 FCM Background Message Received');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // FCM automatically handles background notifications
  // No need to manually show notifications here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set background message handler BEFORE any other Firebase operations
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize app data
  await AppData().initialize();
  
  // Initialize FCM notification service
  final fcmNotificationService = FCMNotificationService();
  await fcmNotificationService.initialize();
  
  // Set system UI mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('🚀 App initialization completed');
  
  runApp(ProviderScope(child: InnovatorHomePage(fcmNotificationService)));
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  final FCMNotificationService notificationService;

  const InnovatorHomePage(this.notificationService, {super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  late StreamSubscription<NotificationResponse> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen to notification taps
    _notificationSubscription = widget.notificationService.notificationStream
        .listen(_handleNotificationTap);
    
    // Optional: Subscribe to topics after app starts
    _subscribeToTopics();
    
    debugPrint('📱 App started and listening for notifications');
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        debugPrint('📱 Notification tapped with data: $data');
        
        // Handle navigation based on notification data
        if (data.containsKey('screen')) {
          _navigateToScreen(data['screen'], data);
        } else if (data.containsKey('route')) {
          navigatorKey.currentState?.pushNamed(
            data['route'],
            arguments: data,
          );
        }
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  void _navigateToScreen(String screen, Map<String, dynamic> data) {
    switch (screen.toLowerCase()) {
      case 'chat':
        // Navigate to chat screen
        navigatorKey.currentState?.pushNamed('/chat', arguments: data);
        break;
      case 'profile':
        // Navigate to profile screen
        navigatorKey.currentState?.pushNamed('/profile', arguments: data);
        break;
      case 'orders':
        // Navigate to orders screen
        navigatorKey.currentState?.pushNamed('/orders', arguments: data);
        break;
      case 'home':
      default:
        // Navigate to home screen
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home', 
          (route) => false,
          arguments: data,
        );
        break;
    }
  }

  Future<void> _subscribeToTopics() async {
    // Subscribe to general topics
    await widget.notificationService.subscribeToTopic('general');
    await widget.notificationService.subscribeToTopic('announcements');
    
    // Subscribe to user-specific topics if user is authenticated
    if (AppData().isAuthenticated && AppData().currentUserId != null) {
      await widget.notificationService.subscribeToTopic('user_${AppData().currentUserId}');
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
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
      home: Scaffold(body: const SplashScreen()),
      
      // Define your routes here
      getPages: [
        GetPage(name: '/home', page: () => Scaffold(body: Text('Home Screen'))),
        GetPage(name: '/chat', page: () => Scaffold(body: Text('Chat Screen'))),
        GetPage(name: '/profile', page: () => Scaffold(body: Text('Profile Screen'))),
        GetPage(name: '/orders', page: () => Scaffold(body: Text('Orders Screen'))),
        // Add more routes as needed
      ],
    );
  }
}