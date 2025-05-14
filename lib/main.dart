import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

late Size mq;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) async {
    //final appData = AppData();
    await AppData().initialize();
    // await _initializeFirebase();
    runApp(
        ProviderScope(child: InnovatorHomePage()),
    );
  });
}

class InnovatorHomePage extends StatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  State<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends State<InnovatorHomePage> {
  @override
  Widget build(BuildContext context) {
    /*  
    GetMaterialApp is a widget provided by the GetX package in Flutter. 
    It is an enhanced version of Flutter's MaterialApp that integrates GetX's state management, 
    routing, and dependency injection features. It simplifies navigation and state management 
    in Flutter applications.*/
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
      //home: Signup(),

    home: SplashScreen()
      
    );
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  // final notificationService = NotificationService();
  // await notificationService.initialize();
  // Initialize notifications
  // await setupFlutterNotifications();
  // var result = await FlutterNotificationChannel().registerNotificationChannel(
  //     description: 'For Showing Notifications',
  //     id: 'chats',
  //     importance: NotificationImportance.IMPORTANCE_HIGH,
  //     name: 'Chats');
  // log('\Notification Channel Result:$result');
}
