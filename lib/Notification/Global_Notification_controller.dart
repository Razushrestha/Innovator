// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class GlobalNotificationController extends GetxController {
//   static GlobalNotificationController get to => Get.find();
  
//   // Observable for in-app notifications
//   final RxList<NotificationModel> inAppNotifications = <NotificationModel>[].obs;
//   final RxBool hasNewNotification = false.obs;
  
//   @override
//   void onInit() {
//     super.onInit();
//     _initializeNotificationListener();
//   }
  
//   void _initializeNotificationListener() {
//     // Listen to Firebase messages while app is in foreground
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       showGlobalNotification(
//         title: message.notification?.title ?? 'New Message',
//         body: message.notification?.body ?? '',
//         data: message.data,
//       );
//     });
//   }
  
//   // Method to show notification on current screen
//   void showGlobalNotification({
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//     Duration duration = const Duration(seconds: 4),
//   }) {
//     // Add to notification list
//     final notification = NotificationModel(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: title,
//       body: body,
//       data: data,
//       timestamp: DateTime.now(),
//     );
    
//     inAppNotifications.insert(0, notification);
//     hasNewNotification.value = true;
    
//     // Show as overlay/snackbar on current screen
//     _showOverlayNotification(notification, duration);
    
//     // Auto-remove after duration
//     Future.delayed(duration + const Duration(seconds: 1), () {
//       removeNotification(notification.id);
//     });
//   }
  
//   void _showOverlayNotification(NotificationModel notification, Duration duration) {
//     Get.rawSnackbar(
//       title: notification.title,
//       message: notification.body,
//       backgroundColor: Get.theme.primaryColor.withOpacity(0.9),
//       //Tex//: Colors.white,
//       duration: duration,
//       snackPosition: SnackPosition.TOP,
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       icon: const Icon(Icons.notifications, color: Colors.white),
//       shouldIconPulse: true,
//       onTap: (snack) {
//         // Handle notification tap
//         _handleNotificationTap(notification);
//         Get.back(); // Close snackbar
//       },
//       mainButton: TextButton(
//         onPressed: () => Get.back(),
//         child: const Text('Dismiss', style: TextStyle(color: Colors.white70)),
//       ),
//     );
//   }
  
//   void _handleNotificationTap(NotificationModel notification) {
//     if (notification.data != null) {
//       final screen = notification.data!['screen'];
//       if (screen != null) {
//         Get.toNamed(screen, arguments: notification.data);
//       }
//     }
//   }
  
//   void removeNotification(String id) {
//     inAppNotifications.removeWhere((n) => n.id == id);
//     if (inAppNotifications.isEmpty) {
//       hasNewNotification.value = false;
//     }
//   }
  
//   void clearAllNotifications() {
//     inAppNotifications.clear();
//     hasNewNotification.value = false;
//   }
// }

// // 2. Notification Model
// class NotificationModel {
//   final String id;
//   final String title;
//   final String body;
//   final Map<String, dynamic>? data;
//   final DateTime timestamp;
  
//   NotificationModel({
//     required this.id,
//     required this.title,
//     required this.body,
//     this.data,
//     required this.timestamp,
//   });
// }