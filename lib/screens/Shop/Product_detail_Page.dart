import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String baseUrl;
  final String? authToken;

  const ProductDetailPage({
    Key? key,
    required this.productId,
    required this.baseUrl,
    this.authToken,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  Map<String, dynamic>? _product;
  bool _addingToCart = false;
  int _quantity = 1;
  bool _isMounted = true;
  int _currentImageIndex = 0; // Track current image in carousel

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    if (!_isMounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (widget.authToken != null) 'authorization': 'Bearer ${widget.authToken}',
      };

      developer.log('Loading product details for ID: ${widget.productId}');
      final requestUrl = '${widget.baseUrl}/api/v1/products/${widget.productId}';
      developer.log('Request URL: $requestUrl');
      
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (!_isMounted) return;

      developer.log('Response status code: ${response.statusCode}');
      
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        developer.log('Received HTML response instead of JSON');
        setState(() {
          _isError = true;
          _errorMessage = 'Server returned HTML instead of JSON. Please check API configuration.';
        });
        return;
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          developer.log('Response data: ${data.toString().substring(0, min(100, data.toString().length))}...');
          
          if (data['data'] != null) {
            setState(() {
              _product = data['data'];
            });
          } else {
            setState(() {
              _isError = true;
              _errorMessage = 'Product details not available';
            });
          }
        } catch (e) {
          developer.log('JSON parse error: $e');
          developer.log('Response body: ${response.body.substring(0, min(200, response.body.length))}...');
          setState(() {
            _isError = true;
            _errorMessage = 'Failed to parse server response: $e';
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!_isMounted) return;
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
      developer.log('Error loading product details: $e');
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    if (!_isMounted) return;

    // Validate auth token
    if (widget.authToken == null) {
      _showMessage('Please log in to add items to your cart', isError: true);
      return;
    }

    // Validate product data
    if (_product == null) {
      _showMessage('Product data not available', isError: true);
      return;
    }

    final String productId = _product!['_id'] ?? '';
    final double price = (_product!['price'] ?? 0.0).toDouble();
    final int stock = _product!['stock'] ?? 0;
    final String productName = _product!['name'] ?? 'Unknown Product';

    // Check stock
    if (stock < _quantity) {
      _showMessage('Not enough items in stock', isError: true);
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${widget.authToken}',
      };

      developer.log('Adding product $productId to cart, quantity: $_quantity');
      
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/v1/add-to-cart'),
        headers: headers,
        body: json.encode({
          'product': productId,
          'productName': productName,
          'quantity': _quantity,
          'price': price,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (!_isMounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _showMessage('$productName added to cart successfully');
        } else {
          _showMessage(data['message'] ?? 'Failed to add item to cart', isError: true);
        }
      } else {
        _showMessage('Failed to add item to cart: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      developer.log('Error adding to cart: $e');
      if (_isMounted) {
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!_isMounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _incrementQuantity() {
    final int stock = _product?['stock'] ?? 0;
    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
    } else {
      _showMessage('Cannot add more items than available in stock', isError: true);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        title: Text(_product != null ? _product!['name'] ?? 'Product Detail' : 'Product Detail', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductDetails,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Failed to load product details'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return const Center(child: Text('No product data available'));
    }

    // Extract product details
    final String name = _product!['name'] ?? 'Unknown Product';
    final String description = _product!['description'] ?? 'No description available';
    final double price = (_product!['price'] ?? 0.0).toDouble();
    final int stock = _product!['stock'] ?? 0;
    final List<dynamic> images = _product!['images'] ?? [];
    final String category = _product!['category']?['name'] ?? 'Uncategorized';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product images carousel
          _buildImageCarousel(images),
          const SizedBox(height: 24),
          
          // Product name
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Category
          Text(
            'Category: $category',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          
          // Price and stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\NPR ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stock > 0 ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  stock > 0 ? 'In Stock: $stock' : 'Out of stock',
                  style: TextStyle(
                    color: stock > 0 ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          
          // Additional product details
          const SizedBox(height: 24),
          _buildProductSpecs(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16/9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: images.length > 1,
            autoPlay: images.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              if (_isMounted) {
                setState(() {
                  _currentImageIndex = index;
                });
              }
            },
          ),
          items: images.map((image) {
            final String imageUrl = '${widget.baseUrl}$image';
            return Hero(
              tag: 'product-${widget.productId}-${images.indexOf(image)}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == entry.key
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.5),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildProductSpecs() {
    // Extract additional product details if available
    final Map<String, dynamic> specs = {};
    
    // Add any details from the product data
    if (_product!.containsKey('content')) specs['Content'] = _product!['content'];
    if (_product!.containsKey('vendor') && _product!['vendor'] != null) {
      specs['Business'] = _product!['vendor']['businessName'] ?? 'Unknown Vendor';
    }
    
    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...specs.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                '${entry.key}:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8), 
              Expanded(
                child: Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBottomBar() {
    final int stock = _product!['stock'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: stock > 0 ? _decrementQuantity : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: stock > 0 ? _incrementQuantity : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: (stock > 0 && !_addingToCart) ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _addingToCart
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}