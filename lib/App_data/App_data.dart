// Create a new file: lib/services/app_data.dart

import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class AppData {
  // Singleton instance
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // In-memory storage
  String? _authToken;
  
  // Token key for SharedPreferences
  static const String _tokenKey = 'auth_token';
  
  // Getter for token
  String? get authToken => _authToken;
  
  // Initialize app data (call this at app startup)
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      log('AppData initialized with token: ${_authToken != null ? "Token exists" : "No token"}');
    } catch (e) {
      log('Error initializing AppData: $e');
    }
  }
  
  // Set token (both in memory and SharedPreferences)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      log('Token saved successfully in AppData');
    } catch (e) {
      log('Error saving token in AppData: $e');
    }
  }
  
  // Clear token (both from memory and SharedPreferences)
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      log('Token cleared from AppData');
    } catch (e) {
      log('Error clearing token from AppData: $e');
    }
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;


  //Current user
  //
  // 
}