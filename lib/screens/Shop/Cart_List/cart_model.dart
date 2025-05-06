// cart_model.dart
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
      status: json['status'],
      data: (json['data'] as List).map((item) => CartItem.fromJson(item)).toList(),
      error: json['error'],
      message: json['message'],
    );
  }
}

class CartItem {
  final String id;
  final String email;
  final String product;
  final String productName;  // Add this field
  final int price;
  final int quantity;
  final int v;

  CartItem({
    required this.id,
    required this.email,
    required this.product,
    required this.productName,  // Add to constructor
    required this.price,
    required this.quantity,
    required this.v,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      email: json['email'],
      product: json['product'],
      productName: json['name'] ?? 'Unknown Product',  // Parse from JSON
      price: json['price'],
      quantity: json['quantity'],
      v: json['__v'],
    );
  }
}