// Updated cart_model.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CartListResponse {
  final int status;
  final List<CartItem> data;
  final dynamic error;
  final String message;

  CartListResponse({
    required this.status,
    required this.data,
    required this.error,
    required this.message,
  });

  factory CartListResponse.fromJson(Map<String, dynamic> json) {
    return CartListResponse(
      status: json['status'] ?? 0,
      data: json['data'] != null 
          ? (json['data'] as List).map((item) => CartItem.fromJson(item)).toList()
          : [],
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

class CartItem {
  final String id;
  final String email;
  final String productId;
  final String productName;
  final int price;
  final int quantity;
  final int v;
  final List<String> images; // Changed to List<String>

  CartItem({
    required this.id,
    required this.email,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.v,
    required this.images,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Extract product information
    final product = json['product'] is Map ? json['product'] as Map<String, dynamic> : null;
    
    // Handle images - they should come from the product object
    List<String> images = [];
    if (product != null && product['images'] is List) {
      images = (product['images'] as List).map((e) => e.toString()).toList();
    }

    return CartItem(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      productId: product?['_id']?.toString() ?? json['product']?.toString() ?? '',
      productName: product?['name']?.toString() ?? json['productName']?.toString() ?? 'Unknown Product',
      price: (product?['price'] ?? json['price'] ?? 0).toInt(),
      quantity: (json['quantity'] ?? 0).toInt(),
      v: (json['__v'] ?? 0).toInt(),
      images: images,
    );
  }
}


