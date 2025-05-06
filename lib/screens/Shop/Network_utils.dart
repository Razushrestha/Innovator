import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class NetworkUtils {
  static const String baseUrl = "http://182.93.94.210:3064";
  
  // Generic GET request handler with improved error handling and logging
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
    String? authToken,
  }) async {
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        if (requiresAuth && authToken != null) 'Authorization': 'Bearer $authToken',
        if (headers != null) ...headers,
      };

      developer.log('GET request to: $baseUrl$endpoint');
      developer.log('Headers: $requestHeaders');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: requestHeaders,
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return data;
      } else {
        // Handle error responses
        var errorMessage = 'Request failed with status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Failed to parse error response
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
    }
  }

  // Generic POST request handler with improved error handling and logging
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
    String? authToken,
  }) async {
    try {
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        if (requiresAuth && authToken != null) 'Authorization': 'Bearer $authToken',
        if (headers != null) ...headers,
      };

      developer.log('POST request to: $baseUrl$endpoint');
      developer.log('Headers: $requestHeaders');
      if (body != null) {
        developer.log('Body: ${json.encode(body)}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return data;
      } else {
        // Handle error responses
        var errorMessage = 'Request failed with status: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Failed to parse error response
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Network error: $e');
      rethrow;
    }
  }

  // Helper method to fetch shop products with pagination
  static Future<List<dynamic>> getShopProducts(int page, String? authToken) async {
    try {
      final data = await get(
        '/api/v1/list-shops/$page',
        authToken: authToken,
      );
      
      if (data['data'] != null && data['data'] is List) {
        return data['data'];
      }
      return [];
    } catch (e) {
      developer.log('Error fetching shop products: $e');
      rethrow;
    }
  }

  // Helper method to fetch a specific product details
  static Future<Map<String, dynamic>> getProductDetails(String productId, String? authToken) async {
    try {
      final data = await get(
        '/api/v1/get-shop/$productId',
        authToken: authToken,
      );
      
      if (data['data'] != null && data['data'] is Map<String, dynamic>) {
        return data['data'];
      }
      return {};
    } catch (e) {
      developer.log('Error fetching product details: $e');
      rethrow;
    }
  }

  // Add to cart helper method
  static Future<Map<String, dynamic>> addToCart(
    String productId,
    int quantity,
    String? authToken,
  ) async {
    if (authToken == null) {
      throw Exception('Authentication required to add items to cart');
    }
    
    return await post(
      '/api/v1/add-to-cart',
      body: {
        'productId': productId,
        'quantity': quantity,
      },
      authToken: authToken,
    );
  }
}