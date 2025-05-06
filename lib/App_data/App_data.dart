import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Enhanced getter with debug logging
  String? get currentUserEmail {
    final email = _currentUser?['email'];
    developer.log('Getting current user email: $email');
    return email;
  }
  
  String? get currentUserId => _currentUser?['id'];
  String? get currentUserName => _currentUser?['name'];
  
  // Initialize app data (call this at app startup)
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load auth token
      _authToken = prefs.getString(_tokenKey);
      
      // Load current user data
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
        developer.log('Loaded user data: $_currentUser');
      } else {
        developer.log('No user data found in SharedPreferences');
      }
      
      developer.log('AppData initialized: ${_authToken != null ? "Token exists" : "No token"}, ${_currentUser != null ? "User exists" : "No user"}');
    } catch (e) {
      developer.log('Error initializing AppData: $e');
    }
  }
  
  // Set token (both in memory and SharedPreferences)
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
  
  // Clear token (both from memory and SharedPreferences)
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
  
  // Enhanced helper to check if this is the current user with debug logging
  bool isCurrentUser(String userId) {
    final result = _currentUser != null && _currentUser!['id'] == userId;
    developer.log('isCurrentUser check - Current user ID: ${_currentUser?['id']}, Comparing with: $userId, Result: $result');
    return result;
  }

  /*
 ronit 
  nfh
  n ronit 
  nkjdf
  */
  
  // Enhanced helper to check if this is the current user by email with debug logging
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
  
  // Check if user is authenticated
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  
  // Logout - clear all user data
  Future<void> logout() async {
    await clearAuthToken();
    await clearCurrentUser();
    developer.log('User logged out - all data cleared');
  }
}