import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/firebase_options.dart';

import 'package:innovator/innovator_home.dart';
import 'package:innovator/utils/routing.dart';


@pragma('vm:entry-point')Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
}
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
 SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) async {
    await _initializeFirebase();
    runApp(const InnovatorHomePage(
     
    ));
  });
}

late Size mq;

class InnovatorHomePage extends StatelessWidget {
  const InnovatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    /*  
    GetMaterialApp is a widget provided by the GetX package in Flutter. 
    It is an enhanced version of Flutter's MaterialApp that integrates GetX's state management, 
    routing, and dependency injection features. It simplifies navigation and state management 
    in Flutter applications.*/
    return MaterialApp(
      title: 'Inovator',
      theme: ThemeData(
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
      home: LoginPage(),

      // //home:  InnovatorHomePage(),
      // initialRoute: '/',
      // debugShowCheckedModeBanner: false,

      // //adding routes show that we can moved from one page to another page smoothly
      // routes: {
      //  '/': (context) => InnovatorHomePage(), //directing to splash screen
      //  //Authenticator.signuproute: (context) =>  signup(), //naviagting to signup page
      //  //Myroutes.homeroute: (context) => const InnovatorHomePage(), //naviagting to home page
      

      //  // Myroutes.homeroute: (context) => const Homepage(), //naviagting to home page
      //   //Myroutes.loginroute: (context) => const LoginPage(), //naviagting to login page
      //   //Myroutes.homeroute: (context) => const BooksPage(), //naviagting to books page
      // },
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
