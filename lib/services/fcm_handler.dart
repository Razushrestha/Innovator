import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class FCMHandler {
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/innovator-250f8/messages:send';
  static ServiceAccountCredentials? _credentials;
  static AuthClient? _authClient;

  static Future<void> initialize(String serviceAccountJson) async {
    try {
      // Parse the service account JSON
      _credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      // Define the required scopes for FCM
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      // Obtain an authenticated HTTP client
      _authClient = await clientViaServiceAccount(_credentials!, scopes);
      debugPrint('🔥 FCMHandler initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Error initializing FCMHandler: $e');
      throw Exception('Failed to initialize FCMHandler');
    }
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
    if (_authClient == null || _credentials == null) {
      throw Exception('FCMHandler not initialized. Call initialize() first.');
    }

    try {
      final response = await _authClient!.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'topic': 'user_$userId', // Assuming users are subscribed to their own topics
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': type,
              'screen': screen,
              'click_action': click_action ?? 'FLUTTER_NOTIFICATION_CLICK',
              ...?data,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('🔥 FCM notification sent successfully to user: $userId');
        return true;
      } else {
        debugPrint('⚠️ FCM notification failed with status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error sending FCM notification: $e');
      return false;
    }
  }

  static void dispose() {
    _authClient?.close();
    _authClient = null;
    _credentials = null;
  }
}