import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'dart:convert';
import 'package:innovator/screens/Course/model/courses_model.dart';
import 'dart:developer' as developer;

class CourseService {
  final String baseUrl = 'http://182.93.94.210:3064/api/v1';
  final AppData _appData = AppData();

  // Method to fetch courses with optional pagination
  Future<List<Data>?> fetchCourses({int page = 0}) async {
    try {
      final authToken = _appData.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        developer.log('Cannot fetch courses: No auth token available');
        throw Exception('Authentication required to fetch courses');
      }

      developer.log('Fetching courses for page: $page');
      
      // Try both URL formats to see which one works
      // Option 1: Simple path parameter
      final url = Uri.parse('$baseUrl/list-courses/$page');
      
      developer.log('Making request to: ${url.toString()}');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        developer.log('Courses fetched successfully');
        
        // Log the raw response to analyze the structure
        developer.log('Raw response: ${response.body.substring(0, min(100, response.body.length))}...');
        
        // Parse JSON with extra safety
        dynamic jsonData;
        try {
          jsonData = json.decode(response.body);
          developer.log('JSON decoded successfully');
        } catch (e) {
          developer.log('JSON decode error: $e');
          throw Exception('Error parsing JSON response: $e');
        }
        
        // Extract data safely
        if (jsonData is Map<String, dynamic>) {
          try {
            // Create courses object with custom parsing
            final courses = Courses.fromJson(jsonData);
            developer.log('Courses parsed successfully, found ${courses.data.length} courses');
            return courses.data;
          } catch (e) {
            developer.log('Error in Courses.fromJson: $e');
            
            // Alternative manual parsing approach
            if (jsonData.containsKey('data') && jsonData['data'] is List) {
              developer.log('Attempting manual parsing of data list');
              final dataList = (jsonData['data'] as List)
                  .map((item) => Data.fromJson(item))
                  .toList();
              return dataList;
            } else {
              throw Exception('Cannot parse courses data: $e');
            }
          }
        } else {
          developer.log('Response is not a Map: ${jsonData.runtimeType}');
          throw Exception('Invalid response format');
        }
      } else {
        developer.log('Failed to load courses. Status code: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        throw Exception(
            'Failed to load courses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  // Helper function to get minimum of two values
  int min(int a, int b) {
    return a < b ? a : b;
  }

  // Method to fetch a specific course by ID
  Future<Data?> fetchCourseById(String courseId) async {
    try {
      final authToken = _appData.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        developer.log('Cannot fetch course: No auth token available');
        throw Exception('Authentication required to fetch course details');
      }

      developer.log('Fetching course with ID: $courseId');
      
      final url = Uri.parse('$baseUrl/course/$courseId');
      
      developer.log('Making request to: ${url.toString()}');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        developer.log('Course fetched successfully');
        
        // Log the raw response to analyze the structure
        developer.log('Raw response: ${response.body.substring(0, min(100, response.body.length))}...');
        
        dynamic jsonData;
        try {
          jsonData = json.decode(response.body);
        } catch (e) {
          developer.log('JSON decode error: $e');
          throw Exception('Error parsing JSON response: $e');
        }
        
        // Check data structure and extract course
        if (jsonData is Map<String, dynamic>) {
          try {
            if (jsonData.containsKey('data') && jsonData['data'] is Map<String, dynamic>) {
              return Data.fromJson(jsonData['data']);
            } else if (jsonData.containsKey('data') && jsonData['data'] is List && 
                     (jsonData['data'] as List).isNotEmpty) {
              return Data.fromJson((jsonData['data'] as List).first);
            } else {
              // Try parsing the whole response
              return Data.fromJson(jsonData);
            }
          } catch (e) {
            developer.log('Error parsing course data: $e');
            throw Exception('Error parsing course data: $e');
          }
        } else {
          developer.log('Response is not a Map: ${jsonData.runtimeType}');
          throw Exception('Invalid response format');
        }
      } else {
        developer.log('Failed to load course. Status code: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        throw Exception(
            'Failed to load course. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching course: $e');
      throw Exception('Error fetching course: $e');
    }
  }
}