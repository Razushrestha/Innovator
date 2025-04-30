import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton class to store application-wide data and user session information
class AppDatas with ChangeNotifier {
  // Singleton instance
  static final AppDatas _instance = AppDatas._internal();
  
  // Factory constructor
  factory AppDatas() => _instance;
  
  // Private constructor for singleton
  AppDatas._internal();
  
  // Authentication token (format: "userId|actualToken")
  String? _authToken;
  
  // User information
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPicture;
  Map<String, dynamic>? _userData;
  
  // App settings and preferences
  bool _isDarkMode = false;
  String _language = 'en';
  
  // Getters
  String? get authToken => _authToken;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPicture => _userPicture;
  Map<String, dynamic>? get userData => _userData;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  
  /// Initialize AppData from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load auth data
    _authToken = prefs.getString('auth_token');
    _parseAuthToken();
    
    // Load user data
    final userDataString = prefs.getString('user_data');
    if (userDataString != null && userDataString.isNotEmpty) {
      try {
        _userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _userName = _userData?['name'] as String?;
        _userEmail = _userData?['email'] as String?;
        _userPicture = _userData?['picture'] as String?;
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
    
    // Load app settings
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _language = prefs.getString('language') ?? 'en';
    
    notifyListeners();
  }
  
  /// Parse the auth token to extract the user ID
  void _parseAuthToken() {
    if (_authToken != null && _authToken!.contains('|')) {
      _userId = _authToken!.split('|').first;
    } else {
      _userId = null;
    }
  }
  
  /// Set authentication token and save to SharedPreferences
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    _parseAuthToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    
    notifyListeners();
  }
  
  /// Set user data and save to SharedPreferences
  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;
    _userName = userData['name'] as String?;
    _userEmail = userData['email'] as String?;
    _userPicture = userData['picture'] as String?;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    
    notifyListeners();
  }
  
  /// Update user profile picture
  Future<void> updateUserPicture(String picturePath) async {
    _userPicture = picturePath;
    
    if (_userData != null) {
      _userData!['picture'] = picturePath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_userData));
    }
    
    notifyListeners();
  }
  
  /// Toggle dark mode setting
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    
    notifyListeners();
  }
  
  /// Set application language
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    notifyListeners();
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  
  /// Clear all user data and authentication (logout)
  Future<void> clearUserData() async {
    _authToken = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPicture = null;
    _userData = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    notifyListeners();
  }
}