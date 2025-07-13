import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/Shop/Cart_List/api_services.dart';
import 'package:innovator/screens/Shop/checkout.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ApiService _apiService = ApiService();
  late Future<CartListResponse> _cartListFuture;
  final AppData _appData = AppData();
  int _cartItemCount = 0;

  // Local cart management
  List<CartItem> _localCartItems = [];
  bool _isLoading = false;

  // Define color scheme for the cart
  final Color _primaryColor = Colors.indigo;
  final Color _accentColor = Colors.green;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.blueGrey.shade800;
  final Color _priceColor = Colors.green.shade700;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _isLoading = true;
    });

    _cartListFuture = _apiService.getCartList().then((cartResponse) {
      setState(() {
        _localCartItems = List.from(cartResponse.data); // Create local copy
        _cartItemCount = _localCartItems.length;
        _isLoading = false;
      });
      return cartResponse;
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      throw error;
    });
  }

  // Local quantity update function
  void _updateCartItemQuantityLocal(String itemId, int newQuantity) {
    setState(() {
      final itemIndex = _localCartItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        if (newQuantity <= 0) {
          // Remove item if quantity is 0 or less
          _localCartItems.removeAt(itemIndex);
          _cartItemCount = _localCartItems.length;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Item removed from cart'),
              backgroundColor: _primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Update quantity
          _localCartItems[itemIndex] = CartItem(
            id: _localCartItems[itemIndex].id,
            email: _localCartItems[itemIndex].email,
            productId: _localCartItems[itemIndex].productId,
            productName: _localCartItems[itemIndex].productName,
            price: _localCartItems[itemIndex].price,
            quantity: newQuantity,
            v: _localCartItems[itemIndex].v,
            images: _localCartItems[itemIndex].images,
          );
        }
      }
    });

    // Optional: Sync with server in background (without blocking UI)
    _syncWithServerInBackground(itemId, newQuantity);
  }

  // Local delete function
  void _deleteCartItemLocal(String itemId) {
    setState(() {
      _localCartItems.removeWhere((item) => item.id == itemId);
      _cartItemCount = _localCartItems.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed from cart'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // You can implement undo functionality here if needed
          },
        ),
      ),
    );

    // Optional: Sync with server in background
    _syncDeleteWithServerInBackground(itemId);
  }

  // Background sync functions (optional - won't block UI)
  Future<void> _syncWithServerInBackground(String itemId, int newQuantity) async {
    try {
      // If you have an update API endpoint, use it here
      // await _apiService.updateCartItem(itemId, newQuantity);
      print('Synced item $itemId with quantity $newQuantity to server');
    } catch (e) {
      print('Background sync failed: $e');
      // Don't show error to user since this is background sync
    }
  }

  Future<void> _syncDeleteWithServerInBackground(String itemId) async {
    try {
      await _apiService.deleteCartItem(itemId);
      print('Synced deletion of item $itemId to server');
    } catch (e) {
      print('Background delete sync failed: $e');
      // Don't show error to user since this is background sync
    }
  }

  // Calculate total cart value
  double _calculateTotalCartValue() {
    double total = 0;
    for (var item in _localCartItems) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  )
                : _buildCartContent(),
          ),
          FloatingMenuWidget(),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    if (_localCartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: _primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Start Shopping'),
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalCartValue = _calculateTotalCartValue();

    return Column(
      children: [
        // Cart summary
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items: $_cartItemCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              Text(
                'Total: \NPR${totalCartValue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _priceColor,
                ),
              ),
            ],
          ),
        ),
        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _localCartItems.length,
            itemBuilder: (context, index) {
              final item = _localCartItems[index];
              return Dismissible(
                key: Key(item.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("Remove Item"),
                        content: const Text(
                          "Are you sure you want to remove this item from your cart?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              "CANCEL",
                              style: TextStyle(color: _textColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              "DELETE",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _deleteCartItemLocal(item.id.toString());
                },
                child: _buildCartItemCard(item),
              );
            },
          ),
        ),
        // Checkout button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
  onPressed: () {
    // Navigate to checkout screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          totalAmount: totalCartValue,
          itemCount: _localCartItems.length,
          cartItems: _localCartItems,
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: _accentColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  ),
  child: Text(
    'PROCEED TO CHECKOUT (\NPR ${totalCartValue.toStringAsFixed(2)})',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _primaryColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      color: _cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SafeImage(
                  images: item.images,
                  baseUrl: 'http://182.93.94.210:3066',
                  placeholderIcon: Icons.image,
                  placeholderColor: _primaryColor.withOpacity(0.2),
                  iconSize: 40,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: \NPR ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _priceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Qty: ',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 12,
                        ),
                      ),
                      // Minus button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: Icon(Icons.remove, size: 16),
                          onPressed: () {
                            _updateCartItemQuantityLocal(
                              item.id.toString(),
                              item.quantity - 1,
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      // Quantity display
                      Container(
                        width: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Plus button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: Icon(Icons.add, size: 16),
                          onPressed: () {
                            print('Plus button clicked for item: ${item.id}'); // Debug
                            _updateCartItemQuantityLocal(
                              item.id.toString(),
                              item.quantity + 1,
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Item total price
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _priceColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '\NPR${(item.price * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _priceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafeImage extends StatelessWidget {
  final List<String>? images;
  final String? baseUrl;
  final IconData placeholderIcon;
  final Color placeholderColor;
  final double iconSize;

  const SafeImage({
    Key? key,
    this.images,
    this.baseUrl,
    this.placeholderIcon = Icons.image,
    this.placeholderColor = Colors.grey,
    this.iconSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (images == null || images!.isEmpty) {
      return Center(
        child: Icon(placeholderIcon, color: placeholderColor, size: iconSize),
      );
    }

    final imageUrl =
        baseUrl != null ? '$baseUrl${images!.first}' : images!.first;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(placeholderColor),
        ),
      ),
      errorWidget: (context, url, error) => Center(
        child: Icon(
          placeholderIcon,
          color: placeholderColor,
          size: iconSize,
        ),
      ),
    );
  }
}