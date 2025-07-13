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
  final String _baseUrl = "http://182.93.94.210:3066";
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
    }
  }

  void _onSearchChanged() {
    final now = DateTime.now();
    if (_lastSearchTime == null ||
        now.difference(_lastSearchTime!).inMilliseconds > 500) {
      _lastSearchTime = now;
      final newSearchQuery = _searchController.text.trim();
      
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
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$productName added to cart')),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Categories list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryTile(
                    icon: Icons.all_inclusive,
                    title: 'All Categories',
                    isSelected: _selectedCategoryId == null,
                    onTap: () {
                      _onCategorySelected(null, 'All Categories');
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),
                  ..._categories.map((category) {
                    final categoryId = category['_id'] ?? '';
                    final categoryName = category['name'] ?? 'Unknown Category';
                    final isSelected = _selectedCategoryId == categoryId;
                    
                    return _buildCategoryTile(
                      icon: Icons.category,
                      title: categoryName,
                      isSelected: isSelected,
                      onTap: () {
                        _onCategorySelected(categoryId, categoryName);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildBody(),
          FloatingMenuWidget(),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Enhanced search bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Enhanced cart button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.fromRGBO(244, 135, 6, 1), Color.fromRGBO(244, 135, 6, 1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ShoppingCartBadge(
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
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enhanced category filter
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCategoryName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
    );
  }

  Widget _buildBody() {
    if (_isError && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load products',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategoryId != null
                  ? 'No products found for current filters'
                  : 'No products available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: Colors.blue,
      child: Column(
        children: [
          const SizedBox(height: 180), // Space for top bar
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65, // Made taller for bigger images
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final String id = product['_id'] ?? '';
    final String name = product['name'] ?? 'Unknown Product';
    final String description = product['description'] ?? 'No description available';
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
            builder: (context) => ProductDetailPage(
              productId: id,
              baseUrl: _baseUrl,
              authToken: _appData.authToken,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced image section (bigger)
            Container(
              height: 100, // Fixed height instead of Expanded
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [Colors.grey[200]!, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Hero(
                      tag: 'product-$id',
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 160,
                              placeholder: (context, url) => Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey[300]!, Colors.grey[200]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey[300]!, Colors.grey[200]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Stock overlay
                  if (stock <= 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Add to cart button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (stock > 0 && !isAddingToCart)
                              ? () => _addToCart(id, price)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: stock > 0
                                  ? LinearGradient(
                                      colors: [Color.fromRGBO(244, 135, 6, 1), Color.fromRGBO(244, 135, 6, 1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [Colors.grey, Colors.grey.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              shape: BoxShape.circle,
                            ),
                            child: isAddingToCart
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge (if needed)
                  if (product['discount'] != null && product['discount'] > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product['discount']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Enhanced product info section
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ), 
                  ),
                  const SizedBox(height: 6),
                  // Product name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  // Text(
                  //   description,
                  //   style: TextStyle(
                  //     color: Colors.grey[600],
                  //     fontSize: 11,
                  //     height: 1.2,
                  //   ),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  // const SizedBox(height: 6),
                  // Price
                  Text(
                    'NPR ${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock and rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock status
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: stock > 0 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stock > 0 ? 'In Stock ($stock)' : 'Out of Stock',
                            style: TextStyle(
                              color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Rating stars (if available)
                      if (product['rating'] != null) ...[
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              product['rating'].toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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