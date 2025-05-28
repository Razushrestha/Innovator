import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';

class AppData {
  // Singleton instance
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // In-memory storage
  String? _authToken;
  Map<String, dynamic>? _currentUser;
  
  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user';
  
  // Getters
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  String? get currentUserEmail {
    final email = _currentUser?['email'];
    developer.log('Getting current user email: ${email ?? "null"}');
    return email;
  }
  
  String? get currentUserId {
    final id = JwtHelper.extractUserId(_authToken);
    developer.log('Getting current user ID from JWT: ${id ?? "null"}');
    return id;
  } 
  
  String? get currentUserName => _currentUser?['name'];
  
  String? get currentUserProfilePicture => _currentUser?['profilePicture'];
  
  // New getter for fcmTokens
  List<String>? get fcmTokens => _currentUser?['fcmTokens']?.cast<String>();
  
  // Initialize app data
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _authToken = prefs.getString(_tokenKey);
      developer.log('Auth token: ${_authToken ?? "null"}');
      
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        try {
          _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
          developer.log('Loaded user data: $_currentUser');
          if (_currentUser?['_id'] == null) {
            developer.log('Warning: User data does not contain "id" field');
          }
        } catch (e) {
          developer.log('Error decoding user JSON: $e');
          _currentUser = null;
        }
      } else {
        developer.log('No user data found in SharedPreferences');
      }
      
      developer.log('AppData initialized: ${_authToken != null ? "Token exists" : "No token"}, ${_currentUser != null ? "User exists" : "No user"}');
    } catch (e) {
      developer.log('Error initializing AppData: $e');
    }
  }
  
  // Set token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      developer.log('Token saved successfully in AppData');
    } catch (e) {
      developer.log('Error saving token in AppData: $e');
    }
  }
  
  // Clear token
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      developer.log('Token cleared from AppData');
    } catch (e) {
      developer.log('Error clearing token from AppData: $e');
    }
  }
  
  // Set current user data
  Future<void> setCurrentUser(Map<String, dynamic> userData) async {
    if (userData['_id'] == null) {
      developer.log('Error: Attempted to set user data without "_id" field: $userData');
      return;
    }
    _currentUser = userData;
    developer.log('Setting current user: $_currentUser');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(userData);
      await prefs.setString(_currentUserKey, userJson);
      developer.log('Current user data saved successfully');
    } catch (e) {
      developer.log('Error saving current user data: $e');
    }
  }
  
  // Clear current user data
  Future<void> clearCurrentUser() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      developer.log('Current user data cleared');
    } catch (e) {
      developer.log('Error clearing current user data: $e');
    }
  }
  
  // Update specific user field
  Future<void> updateCurrentUserField(String field, dynamic value) async {
    if (_currentUser == null) {
      developer.log('Cannot update user field - current user is null');
      return;
    }
    
    _currentUser![field] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_currentUser);
      await prefs.setString(_currentUserKey, userJson);
      developer.log('Updated user field: $field');
    } catch (e) {
      developer.log('Error updating user field: $e');
    }
  }
  
  // Update profile picture
  Future<void> updateProfilePicture(String pictureUrl) async {
    await updateCurrentUserField('profilePicture', pictureUrl);
    developer.log('Profile picture updated: $pictureUrl');
  }
  
  // New method to save or update FCM token
  Future<void> saveFcmToken(String fcmToken) async {
    if (_currentUser == null) {
      developer.log('Cannot save FCM token - current user is null');
      return;
    }
    
    // Initialize fcmTokens if it doesn't exist
    _currentUser!['fcmTokens'] ??= [];
    
    // Avoid duplicates
    if (!_currentUser!['fcmTokens'].contains(fcmToken)) {
      _currentUser!['fcmTokens'].add(fcmToken);
      developer.log('FCM token added: $fcmToken');
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = jsonEncode(_currentUser);
        await prefs.setString(_currentUserKey, userJson);
        developer.log('FCM token saved successfully in SharedPreferences');
        
        // Optionally, update the backend
        await _updateFcmTokenOnBackend(fcmToken);
      } catch (e) {
        developer.log('Error saving FCM token to SharedPreferences: $e');
      }
    } else {
      developer.log('FCM token already exists: $fcmToken');
    }
  }
  
  // Helper method to update FCM token on the backend
  Future<void> _updateFcmTokenOnBackend(String fcmToken) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3064/api/v1/update-fcm-token');
      final body = jsonEncode({
        'userId': currentUserId,
        'fcmToken': fcmToken,
      });
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      };
      
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('FCM token updated successfully on backend');
      } else {
        developer.log('Failed to update FCM token on backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error updating FCM token on backend: $e');
    }
  }
  
  bool isCurrentUser(String userId) {
    final currentId = JwtHelper.extractUserId(_authToken);
    final result = currentId != null && currentId == userId;
    developer.log('isCurrentUser check - Current user ID from JWT: ${currentId ?? "null"}, Comparing with: $userId, Result: $result');
    return result;
  }
  
  bool isCurrentUserByEmail(String email) {
    if (_currentUser == null || _currentUser!['email'] == null) {
      developer.log('isCurrentUserByEmail - Current user is null or has no email');
      return false;
    }
    
    final currentEmail = _currentUser!['email'].toString().trim().toLowerCase();
    final compareEmail = email.trim().toLowerCase();
    final result = currentEmail == compareEmail;
    
    developer.log('isCurrentUserByEmail check - Current email: $currentEmail, Comparing with: $compareEmail, Result: $result');
    return result;
  }
  
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  
  Future<void> logout() async {
    await clearAuthToken();
    await clearCurrentUser();
    _authToken = null;
    _currentUser = null;
    developer.log('User logged out - all data cleared');
  }
}