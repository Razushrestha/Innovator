import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Shop/CardIconWidget/CardIconWidget.dart';
import 'package:innovator/screens/Shop/Cart_List/cart_screen.dart';
import 'package:innovator/screens/Shop/Product_detail_Page.dart';
import 'dart:convert';


class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AppData _appData = AppData();
  List<dynamic> _products = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isError = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final String _baseUrl = "http://182.93.94.210:3064";
  // Control how far from the bottom to trigger loading (in pixels)
  final double _scrollThreshold = 200.0;
  // Number of items per page to request
  final int _pageSize = 10;
  // Track products being added to cart
  Map<String, bool> _addingToCart = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initializeData() async {
    await _appData.initialize();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_appData.authToken != null)
          'Authorization': 'Bearer ${_appData.authToken}',
      };

      developer.log(
        'Loading products from page $_currentPage (limit: $_pageSize)',
      );

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/api/v1/list-shops/$_currentPage?limit=$_pageSize',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          final newProducts = data['data'] as List;
          developer.log('Received ${newProducts.length} products');

          setState(() {
            _products.addAll(newProducts);
            _currentPage++;
            _hasMore =
                newProducts.length >=
                _pageSize; // If we got fewer items than requested, we've reached the end
          });
        } else {
          setState(() {
            _hasMore = false;
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
        _showErrorSnackbar('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
      developer.log('Error loading products: $e');
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add to cart function
  Future<void> _addToCart(
  String productId,
  double price, {
  int quantity = 1,
}) async {
  // Validate authentication
  if (_appData.authToken == null) {
    _showErrorSnackbar('Please log in to add items to your cart');
    return;
  }

  // Get product details from local cache
  final product = _products.firstWhere(
    (p) => p['_id'] == productId,
    orElse: () => {'name': 'Unknown Product'},
  );
  final String productName = product['name'] ?? 'Unknown Product';

  // Set loading state for this product
  setState(() {
    _addingToCart[productId] = true;
  });

  try {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_appData.authToken}',
    };

    developer.log('Adding product $productId ($productName) to cart');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/add-to-cart'),
          headers: headers,
          body: json.encode({
            'product': productId,
            'productName': productName,  // Include product name
            'quantity': quantity,
            'price': price,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          },
        );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorSnackbar(data['message'] ?? 'Failed to add $productName to cart');
      }
    } else {
      _showErrorSnackbar(
        'Failed to add $productName to cart: ${response.statusCode}',
      );
    }
  } catch (e) {
    developer.log('Error adding $productName to cart: $e');
    _showErrorSnackbar('Error adding $productName: ${e.toString()}');
  } finally {
    // Clear loading state
    setState(() {
      _addingToCart.remove(productId);
    });
  }
}

  void _scrollListener() {
    // Load more when user gets close to the bottom
    if (_scrollController.position.extentAfter < _scrollThreshold &&
        !_isLoading) {
      _loadProducts();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
          ShoppingCartBadge(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        ).then((_) {
          // Refresh the badge count when returning from cart screen
          setState(() {
            // This will trigger a rebuild of the widget
          });
        });
      },
      badgeColor: Colors.red, // Optional: customize badge color
      iconColor: Colors.black , // Optional: customize icon color
    ),
 
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isError && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Failed to load products'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No products available'),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadProducts, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: _products.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _products.length) {
                  return _buildLoader();
                }
                return _buildProductCard(_products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final String id = product['_id'] ?? '';
    final String name = product['name'] ?? 'Unknown Product';
    final String description =
        product['description'] ?? 'No description available';
    final double price = (product['price'] ?? 0.0).toDouble();
    final int stock = (product['stock']?.toInt() ?? 0) as int;
    final List<dynamic> images = product['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? '$_baseUrl${images[0]}' : '';
    final bool isAddingToCart = _addingToCart[id] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductDetailPage(
                  productId: id,
                  baseUrl: _baseUrl,
                  authToken: _appData.authToken,
                ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack for product image and add to cart button
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Hero(
                      tag: 'product-$id',
                      child:
                          imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                    ),
                  ),

                  // Out of stock overlay
                  if (stock <= 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  // Add to cart button (top-right corner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            (stock > 0 && !isAddingToCart)
                                ? () => _addToCart(id, price)
                                : null,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: stock > 0 ? Colors.blue : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child:
                              isAddingToCart
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\NPR ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Stock: $stock',
                    style: TextStyle(
                      color: stock > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
