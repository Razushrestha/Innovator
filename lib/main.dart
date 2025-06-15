import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/services/Notification_services.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


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
    // Ensure FCMHandler is initialized with the service account key
    // This should ideally be done on the backend
    final serviceAccountJson = '{...}'; // Load securely or call backend
    await FCMHandler.initialize(serviceAccountJson);

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


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('🔥 Background Message: ${message.messageId}');
    debugPrint('🔥 Background Data: ${message.data}');
    debugPrint('🔥 Background Notification: ${message.notification?.title}');
    
    // Initialize notification service and show notification
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.handleForegroundMessage(message);
  } catch (e) {
    debugPrint('❌ Error handling background message: $e');
  }
}

Future<void> _initializeApp() async {
  try {
    debugPrint('🚀 Starting app initialization...');
    
    // Ensure Flutter binding is initialized
     WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

    // Initialize Firebase
    debugPrint('✅ Firebase initialized');
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler set');
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('✅ Notification service initialized');
    
    // Initialize AppData
    await AppData().initialize();
    debugPrint('✅ AppData initialized');
    
    // Initialize FCM
    await AppData().initializeFcm();
    debugPrint('✅ FCM initialized');
    
    // Configure system UI
    await _configureSystemUI();
    debugPrint('✅ System UI configured');
    
    // Initialize cache managers
    await DrawerProfileCache.initialize();
    await CacheManager.initialize();
    debugPrint('✅ Cache managers initialized');
    
    // Initialize GetX controller
    Get.put(UserController());
    debugPrint('✅ Controllers initialized');
    //Get.put(UserController());
  await DrawerProfileCache.initialize();

  await CacheManager.initialize();


    debugPrint('🎉 App initialization completed successfully');
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    rethrow;
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
 
  //  await Firebase.initializeApp();
 
  //await ProfileCacheManager.initialize();


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
     //   _addTestNotificationButton();

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
     // getPages: _buildAppPages(),
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

  // List<GetPage> _buildAppPages() {
  //   return [
  //     GetPage(name: '/splash', page: () => const SplashScreen()),
  //     GetPage(name: '/home', page: () => const HomeScreen()),
  //     GetPage(name: '/chat', page: () => const ChatScreen()),
  //     GetPage(name: '/profile', page: () => const ProfileScreen()),
  //     GetPage(name: '/orders', page: () => const OrdersScreen()),
  //   ];
  // }
}

// Screen Widgets
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     return Scaffold(
//       body: Center(
//         child: Text('Home Screen: ${args ?? ''}'),
//       ),
//     );
//   }
// }

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     return Scaffold(
//       body: Center(
//         child: Text('Chat Screen: ${args ?? ''}'),
//       ),
//     );
//   }
// }

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     return Scaffold(
//       body: Center(
//         child: Text('Profile Screen: ${args ?? ''}'),
//       ),
//     );
//   }
// }

// class OrdersScreen extends StatelessWidget {
//   const OrdersScreen({super.key});
  
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     return Scaffold(
//       body: Center(
//         child: Text('Orders Screen: ${args ?? ''}'),
//       ),
//     );
//   }
// }