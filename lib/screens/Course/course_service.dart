import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'dart:convert';
import 'package:innovator/screens/Course/courses_model.dart';
import 'dart:developer' as developer;

// Import the AppData singleton

class CourseService {
  final String baseUrl = 'http://182.93.94.210:3064/api/v1';
  final AppData _appData = AppData(); // Get the singleton instance

  // Method to fetch courses with optional pagination (page numbers start from 0)
  Future<List<Data>?> fetchCourses({int? page = 0}) async {
    try {
      // Get the auth token from AppData
      final authToken = _appData.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        developer.log('Cannot fetch courses: No auth token available');
        throw Exception('Authentication required to fetch courses');
      }

      // Log the request
      developer.log('Fetching courses for page: $page');
      
      // Create URL with page parameter (API uses :pageNumber format)
      final url = Uri.parse('$baseUrl/list-courses/:$page');
      
      // Make the API request with token from AppData
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        developer.log('Courses fetched successfully');
        final jsonData = json.decode(response.body);
        final courses = Courses.fromJson(jsonData);
        return courses.data;
      } else {
        developer.log('Failed to load courses. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to load courses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      throw Exception('Error fetching courses: $e');
    }
  }

  // Method to fetch a specific course by ID
  Future<Data?> fetchCourseById(String courseId) async {
    try {
      // Get the auth token from AppData
      final authToken = _appData.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        developer.log('Cannot fetch course: No auth token available');
        throw Exception('Authentication required to fetch course details');
      }

      // Log the request
      developer.log('Fetching course with ID: $courseId');
      
      // Create URL
      final url = Uri.parse('$baseUrl/course/$courseId');
      
      // Make the API request with token from AppData
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        developer.log('Course fetched successfully');
        final jsonData = json.decode(response.body);
        // Assuming the API returns a single course with similar structure
        // You might need to adjust this based on your actual API response
        final courseData = Data.fromJson(jsonData['data']);
        return courseData;
      } else {
        developer.log('Failed to load course. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to load course. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching course: $e');
      throw Exception('Error fetching course: $e');
    }
  }
  
  // Alternative method that returns the full Courses object including pagination info (page numbers start from 0)
  Future<Courses> fetchCoursesWithPagination({int? page = 0}) async {
    try {
      // Get the auth token from AppData
      final authToken = _appData.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        developer.log('Cannot fetch courses: No auth token available');
        throw Exception('Authentication required to fetch courses');
      }

      // Log the request
      developer.log('Fetching courses with pagination for page: $page');
      
      // Create URL with page parameter (API uses :pageNumber format)
      final url = Uri.parse('$baseUrl/list-courses/:$page');
      
      // Make the API request with token from AppData
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        developer.log('Courses with pagination fetched successfully');
        final jsonData = json.decode(response.body);
        final courses = Courses.fromJson(jsonData);
        return courses;
      } else {
        developer.log('Failed to load courses. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to load courses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching courses with pagination: $e');
      throw Exception('Error fetching courses with pagination: $e');
    }
  }
}