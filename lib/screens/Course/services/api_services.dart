// services/api_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://182.93.94.210:3066/api/v1';

  // Add these methods to your ApiService class:

// Get course details with lessons, notes, and videos
static Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/courses/$courseId/lessons'),
      headers: {'Content-Type': 'application/json'},
    );

    developer.log('Course Details API Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load course details: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error fetching course details: $e');
    throw Exception('Network error: $e');
  }
}

// Get notes for a specific course (if such endpoint exists)
static Future<Map<String, dynamic>> getCourseNotes(String courseId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/courses/$courseId/notes'),
      headers: {'Content-Type': 'application/json'},
    );

    developer.log('Course Notes API Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load course notes: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error fetching course notes: $e');
    throw Exception('Network error: $e');
  }
}

// Download note file (with authentication if needed)
static Future<bool> downloadNote(String noteUrl, String fileName) async {
  try {
    final response = await http.get(
      Uri.parse(getFullMediaUrl(noteUrl)),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Here you would save the file to device storage
      // This is a placeholder - implement actual file saving
      developer.log('Note downloaded successfully: $fileName');
      return true;
    } else {
      throw Exception('Failed to download note: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error downloading note: $e');
    return false;
  }
}
  
  // Get parent categories
  static Future<Map<String, dynamic>> getParentCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parent-categories'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Parent Categories API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load parent categories: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching parent categories: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get subcategories for a parent category
  static Future<Map<String, dynamic>> getSubcategories(String parentCategoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parent-categories/$parentCategoryId/subcategories'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Subcategories API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load subcategories: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching subcategories: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get courses for a subcategory
  static Future<Map<String, dynamic>> getSubcategoryCourses(String subcategoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subcategories/$subcategoryId/courses'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Subcategory Courses API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get course lessons
  static Future<Map<String, dynamic>> getCourseLessons(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseId/lessons'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Course Lessons API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load lessons: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching lessons: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get notes for a parent category
  static Future<Map<String, dynamic>> getParentCategoryNotes(String parentCategoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parent-categories/$parentCategoryId/notes'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Parent Category Notes API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching notes: $e');
      throw Exception('Network error: $e');
    }
  }

  // Helper method to build full URL for media files
  static String getFullMediaUrl(String relativePath) {
    if (relativePath.isEmpty) return '';
    return 'http://182.93.94.210:3066$relativePath';
  }
}

// Response wrapper classes
class ApiResponse<T> {
  final int status;
  final T? data;
  final String? error;
  final String message;

  ApiResponse({
    required this.status,
    this.data,
    this.error,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      status: json['status'] ?? 0,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'],
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status == 200 && error == null;
}