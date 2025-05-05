import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';

class ApiService {
  static const String baseUrl = 'http://182.93.94.210:3064/api/v1';
  
  // Get headers with auth token if available
  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    final token = AppData().authToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Update content by ID
  static Future<bool> updateContent(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-contents/$id'),
        headers: _headers,
        body: jsonEncode({
          'status': status,
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Update content failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating content: $e');
      return false;
    }
  }
  
  // Delete files
  static Future<bool> deleteFiles(List<String> filePaths) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-files'),
        headers: _headers,
        body: jsonEncode(filePaths),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Delete files failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting files: $e');
      return false;
    }
  }
}