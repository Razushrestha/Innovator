import 'package:flutter/material.dart';
import 'package:innovator/screens/Shop/Cart_List/api_services.dart';
import 'package:innovator/screens/Shop/Cart_List/cart_model.dart';

class ShoppingCartBadge extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? badgeColor;
  final Color? iconColor;

  const ShoppingCartBadge({
    Key? key,
    required this.onPressed,
    this.badgeColor = Colors.red,
    this.iconColor,
  }) : super(key: key);

  @override
  State<ShoppingCartBadge> createState() => _ShoppingCartBadgeState();
}

class _ShoppingCartBadgeState extends State<ShoppingCartBadge> {
  final ApiService _apiService = ApiService();
  int _cartItemCount = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
  }

  Future<void> _loadCartItemCount() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final CartListResponse cartResponse = await _apiService.getCartList();
      
      setState(() {
        _cartItemCount = cartResponse.data.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading cart count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart,
            color: widget.iconColor,
          ),
          onPressed: () {
            // Refresh the cart count when pressed
            _loadCartItemCount();
            widget.onPressed();
          },
        ),
        if (_cartItemCount > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: widget.badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_isLoading)
          Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.badgeColor ?? Colors.red,
                ),
              ),
            ),
          ),
      ],
    );
  }
}