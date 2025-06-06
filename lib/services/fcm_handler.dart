import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class FCMHandler {
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';
  static String? _serverKey;

  static void initialize(String serverKey) {
    _serverKey = serverKey;
  }

  static Future<bool> sendToUser(
    String userId, {
    required String title,
    required String body,
    String? type,
    String? screen,
    Map<String, dynamic>? data,
    String? click_action,
  }) async {
    if (_serverKey == null) {
      throw Exception('FCMHandler not initialized. Call initialize() first.');
    }

    try {
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': '/topics/user_$userId', // Assuming users are subscribed to their own topics
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'type': type,
            'screen': screen,
            'click_action': click_action ?? 'FLUTTER_NOTIFICATION_CLICK',
            ...?data,
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] == 1;
        
        if (success) {
          debugPrint('🔥 FCM notification sent successfully to user: $userId');
        } else {
          debugPrint('⚠️ FCM notification failed: ${response.body}');
        }
        
        return success;
      } else {
        debugPrint('⚠️ FCM notification failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error sending FCM notification: $e');
      return false;
    }
  }
} 