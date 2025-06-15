import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Shop/CardIconWidget/CardIconWidget.dart';
import 'package:innovator/screens/Shop/Cart_List/cart_screen.dart';
import 'package:innovator/screens/Shop/Product_detail_Page.dart';
import 'dart:convert';

import 'package:innovator/widget/FloatingMenuwidget.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppData _appData = AppData();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isError = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final String _baseUrl = "http://182.93.94.210:3064";
  final double _scrollThreshold = 200.0;
  final int _pageSize = 10;
  Map<String, bool> _addingToCart = {};
  bool _isMounted = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _selectedCategoryName = 'All Categories';
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeData() async {
    await _appData.initialize();
    await _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_appData.authToken != null)
          'authorization': 'Bearer ${_appData.authToken}',
      };

      developer.log('Loading categories from: $_baseUrl/api/v1/categories');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/v1/categories'),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
          );

      developer.log('Categories response status: ${response.statusCode}');
      developer.log('Categories response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Handle different possible response structures
          List<dynamic> categoryList = [];
          
          if (data is Map<String, dynamic>) {
            if (data['data'] != null) {
              if (data['data']['categories'] is List) {
                categoryList = data['data']['categories'] as List;
              } else if (data['data'] is List) {
                categoryList = data['data'] as List;
              }
            } else if (data['categories'] is List) {
              categoryList = data['categories'] as List;
            } else if (data is List) {
              categoryList = data as List;
            }
          } else if (data is List) {
            categoryList = data as List;
          }

          if (_isMounted && categoryList.isNotEmpty) {
            setState(() {
              _categories = categoryList;
            });
            developer.log('Loaded ${categoryList.length} categories');
          } else {
            developer.log('No categories found in response');
          }
        } catch (jsonError) {
          developer.log('JSON parsing error for categories: $jsonError');
          developer.log('Response body: ${response.body}');
        }
      } else {
        developer.log('Categories API returned status: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
      }
    } catch (e) {
      developer.log('Error loading categories: $e');
      // Don't show error to user for categories as it's not critical
      // Categories filter will just be hidden if not available
    }
  }

  void _onSearchChanged() {
    // Debounce search to avoid excessive API calls
    final now = DateTime.now();
    if (_lastSearchTime == null ||
        now.difference(_lastSearchTime!).inMilliseconds > 500) {
      _lastSearchTime = now;
      final newSearchQuery = _searchController.text.trim();
      
      // Check if search query changed or if search box is now empty
      if (newSearchQuery != _searchQuery) {
        setState(() {
          _products.clear();
          _currentPage = 0;
          _hasMore = true;
          _searchQuery = newSearchQuery;
        });
        _loadProducts();
      }
    }
  }

  void _onCategorySelected(String? categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _products.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    if (!_isMounted) return;
    
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_appData.authToken != null)
          'authorization': 'Bearer ${_appData.authToken}',
      };

      developer.log(
        'Loading products from page $_currentPage (limit: $_pageSize, search: $_searchQuery, category: $_selectedCategoryId)',
      );

      // Build query parameters
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
      };
      
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        queryParams['category'] = _selectedCategoryId!;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/products').replace(
        queryParameters: queryParams,
      );

      final response = await http
          .get(
            uri,
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

      if (!_isMounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('API Response: ${response.body}');

        if (data['data'] != null && data['data']['products'] is List) {
          final newProducts = data['data']['products'] as List;
          developer.log('Received ${newProducts.length} products');

          if (!_isMounted) return;
          
          setState(() {
            _products.addAll(newProducts);
            _currentPage++;
            // Use the hasMore field from the API response
            _hasMore = data['data']['hasMore'] ?? false;
          });
        } else {
          if (!_isMounted) return;
          
          setState(() {
            _hasMore = false;
          });
        }
      } else {
        if (!_isMounted) return;
        
        setState(() {
          _isError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
        _showErrorSnackbar('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      if (!_isMounted) return;
      
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
      developer.log('Error loading products: $e');
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart(
    String productId,
    double price, {
    int quantity = 1,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (_appData.authToken == null) {
      _showErrorSnackbar('Please log in to add items to your cart');
      return;
    }

    final product = _products.firstWhere(
      (p) => p['_id'] == productId,
      orElse: () => {'name': 'Unknown Product'},
    );
    final String productName = product['name'] ?? 'Unknown Product';

    if (!_isMounted) return;
    
    setState(() {
      _addingToCart[productId] = true;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${_appData.authToken}',
      };

      developer.log('Adding product $productId ($productName) to cart');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/add-to-cart'),
            headers: headers,
            body: json.encode({
              'product': productId,
              'productName': productName,
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

      if (!_isMounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          if (_isMounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('$productName added to cart'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (_isMounted) {
            _showErrorSnackbar(
              data['message'] ?? 'Failed to add $productName to cart',
            );
          }
        }
      } else {
        if (_isMounted) {
          _showErrorSnackbar(
            'Failed to add $productName to cart: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      developer.log('Error adding $productName to cart: $e');
      if (_isMounted) {
        _showErrorSnackbar('Error adding $productName: ${e.toString()}');
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _addingToCart.remove(productId);
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < _scrollThreshold &&
        !_isLoading) {
      _loadProducts();
    }
  }

  void _showErrorSnackbar(String message) {
    if (!_isMounted) return;
    
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
    if (!_isMounted) return;
    
    setState(() {
      _products.clear();
      _currentPage = 0;
      _hasMore = true;
      _searchQuery = '';
      _searchController.clear();
      _selectedCategoryId = null;
      _selectedCategoryName = 'All Categories';
    });
    await _loadProducts();
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Categories'),
              trailing: _selectedCategoryId == null
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _onCategorySelected(null, 'All Categories');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryId = category['_id'] ?? '';
                  final categoryName = category['name'] ?? 'Unknown Category';
                  final isSelected = _selectedCategoryId == categoryId;
                  
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(categoryName),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      _onCategorySelected(categoryId, categoryName);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _buildBody(),
          FloatingMenuWidget(),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.03,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            child: Column(
              children: [
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Shopping cart badge
                    ShoppingCartBadge(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => CartScreen())
                        ).then((_) {
                          if (_isMounted) {
                            setState(() {});
                          }
                        });
                      },
                      badgeColor: Colors.red,
                      iconColor: Colors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category filter row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showCategoryBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.category, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCategoryName,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCategoryId != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => _onCategorySelected(null, 'All Categories'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.clear,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
            Text(
              _searchQuery.isNotEmpty || _selectedCategoryId != null
                  ? 'No products found for current filters'
                  : 'No products available',
            ),
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
          const SizedBox(height: 130), // Increased to account for search bar and category filter
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
    final String category = product['category']?['name'] ?? 'Uncategorized';

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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                            color: stock > 0 ? Colors.orange : Colors.grey,
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
                  const SizedBox(height: 4),
                  Text(
                    'Category: $category',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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