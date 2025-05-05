// Create a new file at: lib/utils/jwt_helper.dart

import 'dart:convert';

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
      final payload = decodeJwt(token);
      return payload?['_id'];
    } catch (e) {
      print('Error extracting user ID: $e');
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