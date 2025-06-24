// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Shop/Cart_List/cart_model.dart';

class ApiService {
  
  static const String baseUrl = 'http://182.93.94.210:3066/api/v1';
  final AppData appData = AppData();

  Future<CartListResponse> getCartList() async {
    final url = Uri.parse('$baseUrl/list-carts');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${appData.authToken}',
      },
    );

    if (response.statusCode == 200) {
      return CartListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load cart list: ${response.statusCode}');
    }
  }

  Future<void> deleteCartItem(String itemId) async {
  final response = await http.delete(
    Uri.parse('http://182.93.94.210:3066/api/v1/delete-cart/$itemId'),
    headers: {
      'authorization': 'Bearer ${appData.authToken}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to delete cart item');
  }
}
}