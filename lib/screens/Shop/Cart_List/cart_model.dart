// Updated cart_model.dart
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
  final String product;
  final String productName;
  final int price;
  final int quantity;
  final int v;
  final String? imageUrl; // Added imageUrl field

  CartItem({
    required this.id,
    required this.email,
    required this.product,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.v,
    this.imageUrl, // Optional image URL
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Handle the product field which might be an object
    String productId = '';
    String? imageUrl;
    
    if (json['product'] is String) {
      productId = json['product'];
    } else if (json['product'] is Map<String, dynamic>) {
      final productMap = json['product'] as Map<String, dynamic>;
      productId = productMap['_id']?.toString() ?? '';
      
      // Try to extract image URL from product object if available
      if (productMap.containsKey('image')) {
        if (productMap['image'] is String) {
          imageUrl = productMap['image'];
        } else if (productMap['image'] is Map && 
                  (productMap['image'] as Map).containsKey('url')) {
          imageUrl = (productMap['image'] as Map)['url']?.toString();
        }
      }
    }
    
    // Handle the name field which might be part of the product object
    String name = 'Unknown Product';
    if (json['name'] != null) {
      if (json['name'] is String) {
        name = json['name'];
      } else if (json['name'] is Map) {
        name = (json['name'] as Map)['title']?.toString() ?? 'Unknown Product';
      }
    } else if (json['product'] is Map && (json['product'] as Map)['name'] != null) {
      // Try to get name from the product object
      final nameValue = (json['product'] as Map)['name'];
      if (nameValue is String) {
        name = nameValue;
      } else if (nameValue is Map) {
        name = nameValue['title']?.toString() ?? 'Unknown Product';
      }
    }
    
    // Also check for image directly in the cart item
    if (imageUrl == null && json['image'] != null) {
      if (json['image'] is String) {
        imageUrl = json['image'];
      } else if (json['image'] is Map && (json['image'] as Map).containsKey('url')) {
        imageUrl = (json['image'] as Map)['url']?.toString();
      }
    }
    
    return CartItem(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      product: productId,
      productName: name,
      price: json['price'] is int ? json['price'] : 0,
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      v: json['__v'] is int ? json['__v'] : 0,
      imageUrl: imageUrl, // Add the extracted image URL
    );
  }
}