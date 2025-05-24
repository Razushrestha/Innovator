// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/App_data/App_data.dart';

// class FCMHomeScreen extends StatefulWidget {
//   const FCMHomeScreen({super.key});

//   @override
//   State<FCMHomeScreen> createState() => _FCMHomeScreenState();
// }

// class _FCMHomeScreenState extends State<FCMHomeScreen> {
//   int _unreadCount = 0;
//   List<NotificationModel> _notifications = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadNotifications();
//     _setupFCMListeners();
//     // Log current user data to debug fcmTokens
//     developer.log('Current user data on FCMHomeScreen init: ${AppData().currentUser}');
//     developer.log('Current fcmTokens: ${AppData().fcmTokens}');
//   }

//   Future<void> _loadNotifications() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await http.get(
//         Uri.parse('http://182.93.94.210:3064/api/v1/notifications'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${AppData().authToken}', // Use AppData token
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _unreadCount = data['data']['unreadCount'] ?? 0;
//           _notifications = (data['data']['notifications'] as List)
//               .map((json) => NotificationModel.fromJson(json))
//               .toList();
//         });
//       } else {
//         developer.log('Failed to load notifications: ${response.statusCode} - ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load notifications: ${response.statusCode}')),
//         );
//       }
//     } catch (e) {
//       developer.log('Error loading notifications: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading notifications: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _setupFCMListeners() {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       FCMService.showNotification(message);
//       _loadNotifications();
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => NotificationScreen(notification: message),
//         ),
//       );
//       _loadNotifications();
//     });
//   }

//   Future<void> _updateFCMToken() async {
//     try {
//       final token = await FirebaseMessaging.instance.getToken();
//       if (token != null) {
//         await AppData().saveFcmToken(token); // Use AppData to save token
//         developer.log('FCM token saved: $token');
//         // Verify the save
//         final updatedUserData = AppData().currentUser;
//         developer.log('Updated user data after FCM save: $updatedUserData');
//         if (updatedUserData?['fcmTokens']?.contains(token) == true) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('FCM token updated successfully')),
//           );
//         } else {
//           developer.log('Error: FCM token not found in fcmTokens array');
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to save FCM token locally')),
//           );
//         }
//       } else {
//         developer.log('Failed to retrieve FCM token');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to retrieve FCM token')),
//         );
//       }
//     } catch (e) {
//       developer.log('Error updating FCM token: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating FCM token: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         actions: [
//           Stack(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.notifications),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => NotificationListScreen(
//                         notifications: _notifications,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               if (_unreadCount > 0)
//                 Positioned(
//                   right: 8,
//                   top: 8,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 16,
//                       minHeight: 16,
//                     ),
//                     child: Text(
//                       '$_unreadCount',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _loadNotifications,
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   const Text(
//                     'Welcome to FCM Notification App',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _updateFCMToken,
//                     child: const Text('Update FCM Token'),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     'Recent Notifications:',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   ..._notifications.take(3).map((notification) => ListTile(
//                         title: Text(notification.content),
//                         subtitle: Text(
//                           'Type: ${notification.type} • ${notification.createdAt}',
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => NotificationScreen(
//                                 notification: RemoteMessage(
//                                   data: {
//                                     'type': notification.type,
//                                     'content': notification.content,
//                                     'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//                                   },
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       )),
//                 ],
//               ),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _loadNotifications,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }
// }

// class NotificationListScreen extends StatelessWidget {
//   final List<NotificationModel> notifications;

//   const NotificationListScreen({super.key, required this.notifications});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('All Notifications')),
//       body: ListView.builder(
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return ListTile(
//             title: Text(notification.content),
//             subtitle: Text(
//               'From: ${notification.sender?.email ?? 'Unknown'} • ${notification.createdAt}',
//             ),
//             trailing: notification.read ? null : const Icon(Icons.brightness_1, size: 12, color: Colors.blue),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => NotificationScreen(
//                     notification: RemoteMessage(
//                       data: {
//                         'type': notification.type,
//                         'content': notification.content,
//                         'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//                       },
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class NotificationModel {
//   final String id;
//   final String type;
//   final String content;
//   final bool read;
//   final String createdAt;
//   final Sender? sender;

//   NotificationModel({
//     required this.id,
//     required this.type,
//     required this.content,
//     required this.read,
//     required this.createdAt,
//     this.sender,
//   });

//   factory NotificationModel.fromJson(Map<String, dynamic> json) {
//     return NotificationModel(
//       id: json['_id'],
//       type: json['type'],
//       content: json['content'],
//       read: json['read'] ?? false,
//       createdAt: json['createdAt'],
//       sender: json['sender'] != null ? Sender.fromJson(json['sender']) : null,
//     );
//   }
// }

// class Sender {
//   final String id;
//   final String email;
//   final String? name;
//   final String? picture;

//   Sender({
//     required this.id,
//     required this.email,
//     this.name,
//     this.picture,
//   });

//   factory Sender.fromJson(Map<String, dynamic> json) {
//     return Sender(
//       id: json['_id'],
//       email: json['email'],
//       name: json['name'],
//       picture: json['picture'],
//     );
//   }
// }

// class FCMService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('notification_icon');

//     final DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification: (id, title, body, payload) async {},
//     );

//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (details) {
//         if (details.payload != null) {
//           final data = json.decode(details.payload!);
//           final message = RemoteMessage(data: Map<String, dynamic>.from(data));
//           _handleNotificationTap(message);
//         }
//       },
//     );

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       showNotification(message);
//     });

//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       _handleNotificationTap(initialMessage);
//     }

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _handleNotificationTap(message);
//     });

//     // Handle token refresh
//     FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
//       await AppData().saveFcmToken(token);
//       developer.log('FCM token refreshed and saved: $token');
//       final updatedUserData = AppData().currentUser;
//       developer.log('User data after token refresh: $updatedUserData');
//     });

//     // Update FCM token on app start
//     await _updateFCMToken();
//   }

//   static Future<void> _updateFCMToken() async {
//     try {
//       final token = await FirebaseMessaging.instance.getToken();
//       if (token != null) {
//         await AppData().saveFcmToken(token);
//         developer.log('FCM token saved: $token');
//         final updatedUserData = AppData().currentUser;
//         developer.log('Updated user data after FCM save: $updatedUserData');
//       } else {
//         developer.log('Failed to retrieve FCM token');
//       }
//     } catch (e) {
//       developer.log('Error updating FCM token: $e');
//     }
//   }

//   static Future<void> showNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     final android = message.notification?.android;
//     final data = message.data;

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'default',
//       'Default Channel',
//       description: 'This channel is used for important notifications.',
//       importance: Importance.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification'),
//     );

//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: channel.description,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       sound: channel.sound,
//       icon: android?.smallIcon ?? 'notification_icon',
//       color: const Color(0xFF4A90E2),
//     );

//     DarwinNotificationDetails iosNotificationDetails =
//         const DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       sound: 'default',
//     );

//     NotificationDetails notificationDetails = NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: iosNotificationDetails,
//     );

//     await _notificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       notification?.title ?? 'New Notification',
//       notification?.body ?? data['content'] ?? 'You have a new notification',
//       notificationDetails,
//       payload: json.encode(message.data),
//     );
//   }

//   static void _handleNotificationTap(RemoteMessage message) {
//     developer.log('Notification tapped with data: ${message.data}');
//     if (message.data['type'] == 'message') {
//       // Navigate to messages screen
//     } else if (message.data['type'] == 'content') {
//       // Navigate to content screen
//     }
//   }
// }

// class NotificationScreen extends StatelessWidget {
//   final RemoteMessage notification;

//   const NotificationScreen({super.key, required this.notification});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Notification Details')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               notification.notification?.title ?? 'Notification',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               notification.notification?.body ??
//                   notification.data['content'] ??
//                   'No content available',
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//             const SizedBox(height: 16),
//             const Text('Additional Data:', style: TextStyle(fontWeight: FontWeight.bold)),
//             ...notification.data.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
//           ],
//         ),
//       ),
//     );
//   }
// }