import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Define the ChatProvider as a Riverpod provider

late Size mq;

void main() async {
  await AppData().initialize();
  WidgetsFlutterBinding.ensureInitialized();
  
  //BackgroundService.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, 
    DeviceOrientation.portraitDown,
  ]).then((value) {
    runApp(
      ProviderScope(
        child: InnovatorHomePage(),
      ),
    );
  });
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    // Add any additional Firebase Messaging setup here if needed
  }

  @override
  Widget build(BuildContext context) {
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
      home: SplashScreen(),
    );
  }
}