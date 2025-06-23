import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/Shop/Cart_List/api_services.dart';
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
      _cartListFuture = _apiService.getCartList().then((cartResponse) {
        setState(() {
          _cartItemCount = cartResponse.data.length;
        });
        return cartResponse;
      });
    });
  }

  Future<void> _updateCartItemQuantity(String itemId, int newQuantity) async {
    try {
      final response = await http.patch(
        Uri.parse('http://182.93.94.210:3065/api/v1/update-cart/$itemId'),
        headers: {
          'authorization': 'Bearer ${_appData.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        _loadCartItems(); // Refresh the cart
      } else {
        throw Exception('Failed to update quantity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCartItem(String itemId) async {
    try {
      await _apiService.deleteCartItem(itemId);
      // Refresh the cart list after deletion
      _loadCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed from cart'),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Add the scaffold key here

      body: Stack(
        children: [
          Container(
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     begin: Alignment.topCenter,
            //     end: Alignment.bottomCenter,

            //   ),
            // ),
            child: FutureBuilder<CartListResponse>(
              future: _cartListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 60),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(fontSize: 16, color: _textColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_appData.authToken == null)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => LoginPage()),
                                (route) => false,
                              );
                              // Navigate to login screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: _primaryColor.withOpacity(50),
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
                            // Navigate to shop
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
                } else {
                  final cartItems = snapshot.data!.data;
                  double totalCartValue = 0;
                  for (var item in cartItems) {
                    totalCartValue += (item.price * item.quantity);
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withAlpha(30),
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
                              'Total: \$${totalCartValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _priceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
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
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text(
                                            "CANCEL",
                                            style: TextStyle(color: _textColor),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
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
                                _deleteCartItem(item.id.toString());
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _primaryColor.withAlpha(20),
                                    width: 1,
                                  ),
                                ),
                                color: _cardColor,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product image
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withAlpha(10),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: SafeImage(
                                            images: item.images,
                                            baseUrl:
                                                'http://182.93.94.210:3065',
                                            placeholderIcon: Icons.image,
                                            placeholderColor: _primaryColor
                                                .withAlpha(50),
                                            iconSize: 40,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              'Price: \$${item.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: _priceColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'Qty: ', // Shortened from 'Quantity: '
                                                  style: TextStyle(
                                                    color: _textColor,
                                                    fontSize:
                                                        12, // Slightly smaller font
                                                  ),
                                                ),
                                                // Minus button
                                                SizedBox(
                                                  width: 32, // Fixed width
                                                  height: 32,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                    ), // Smaller icon
                                                    onPressed: () {
                                                      if (item.quantity > 1) {
                                                        _updateCartItemQuantity(
                                                          item.id,
                                                          item.quantity - 1,
                                                        );
                                                      } else {
                                                        _deleteCartItem(
                                                          item.id,
                                                        );
                                                      }
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                // Quantity display
                                                Container(
                                                  width:
                                                      28, // Fixed width instead of minWidth constraint
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal:
                                                            2, // Reduced padding
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _accentColor
                                                        .withAlpha(20),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ), // Slightly smaller radius
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                      fontSize:
                                                          12, // Smaller font
                                                    ),
                                                  ),
                                                ),
                                                // Plus button
                                                SizedBox(
                                                  width: 32, // Fixed width
                                                  height: 32,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                    ), // Smaller icon
                                                    onPressed: () {
                                                      _updateCartItemQuantity(
                                                        item.id,
                                                        item.quantity + 1,
                                                      );
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    visualDensity:
                                                        VisualDensity.compact,
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
                                          color: _priceColor.withAlpha(10),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _priceColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Checkout'),
                                  content: const Text('Proceed to checkout?'),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Add your checkout logic here
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            // Navigate to checkout
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
                            'PROCEED TO CHECKOUT',
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
              },
            ),
          ),
          FloatingMenuWidget(),
        ],
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
    // If no images or empty list, show placeholder
    if (images == null || images!.isEmpty) {
      return Center(
        child: Icon(placeholderIcon, color: placeholderColor, size: iconSize),
      );
    }

    // Construct full URL if baseUrl is provided
    final imageUrl =
        baseUrl != null ? '$baseUrl${images!.first}' : images!.first;

    // Try to load the image with error handling
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder:
          (context, url) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(placeholderColor),
            ),
          ),
      errorWidget:
          (context, url, error) => Center(
            child: Icon(
              placeholderIcon,
              color: placeholderColor,
              size: iconSize,
            ),
          ),
    );
  }
}
