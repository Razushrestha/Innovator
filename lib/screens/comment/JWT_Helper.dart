// Create a new file at: lib/utils/jwt_helper.dart

import 'dart:convert';
import 'dart:developer' as developer;

class JwtHelper {
  /// Decodes a JWT token and extracts the payload as a Map.
  ///
  /// Returns null if the token is invalid or cannot be decoded.
  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT format');
        return null;
      }
      
      // Decode the payload (middle part)
      final normalizedPayload = _normalizeBase64(parts[1]);
      final payloadBytes = base64Url.decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);
      return json.decode(payloadString);
    } catch (e) {
      print('Error decoding JWT: $e');
      return null;
    }
  }

  /// Extracts the user ID from a JWT token.
  ///
  /// Returns null if the token is invalid or doesn't contain an ID.
  static String? extractUserId(String? token) {
    if (token == null || token.isEmpty) return null;
    
   try {
      final parts = token.split('.');
      if (parts.length != 3) {
        developer.log('Invalid JWT token format');
        return null;
      }
      final payload = parts[1];
      final decoded = base64Url.decode(base64Url.normalize(payload));
      final payloadMap = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
      final userId = payloadMap['sub'] ?? payloadMap['userId'] ?? payloadMap['_id'];
      developer.log('Extracted userId from JWT: ${userId ?? "null"}');
      return userId?.toString();
    } catch (e) {
      developer.log('Error extracting userId from JWT: $e');
      return null;
    }
  }

  /// Normalize base64 string to make it properly padded
  static String _normalizeBase64(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        return output;
      case 2:
        return output + '==';
      case 3:
        return output + '=';
      default:
        return output;
    }
  }
}