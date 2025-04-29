import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Product 1',
      'price': 10.0,
      'quantity': 1,
      'images': [
        'assets/images/product1_1.png',
        'assets/images/product1_2.png',
        'assets/images/product1_3.png',
      ],
      'category': 'Micro-Controller',
    },
    {
      'name': 'Product 2',
      'price': 20.0,
      'quantity': 1,
      'images': [
        'assets/images/product2_1.png',
        'assets/images/product2_2.png',
        'assets/images/product2_3.png',
      ],
      'category': 'Sensors',
    },
    {
      'name': 'Product 3',
      'price': 30.0,
      'quantity': 1,
      'images': [
        'assets/images/product3_1.png',
        'assets/images/product3_2.png',
        'assets/images/product3_3.png',
      ],
      'category': 'Actuators',
    },
    // Add more products here
  ];

  final List<Map<String, dynamic>> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add(product);
    });
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      _cart.remove(product);
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateSelectedCategory(String? category) {
    setState(() {
      _selectedCategory = category!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products
        .where((product) =>
            product['name']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) &&
            (_selectedCategory == 'All' ||
                product['category'] == _selectedCategory))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                    hintStyle: TextStyle(color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: _updateSearchQuery,
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: _updateSelectedCategory,
              dropdownColor: Colors.blueAccent,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              items: <String>['All', 'Micro-Controller', 'Sensors', 'Actuators']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CartPage(cart: _cart)),
                    );
                  },
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          double childAspectRatio = 1;

          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
            childAspectRatio = 1;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
            childAspectRatio = 1;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                product['name'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            CarouselSlider(
              options: CarouselOptions(
                height: 100.0,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                initialPage: 0,
              ),
              items: product['images'].map<Widget>((image) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.asset(image, fit: BoxFit.cover);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price: \$${product['price']}'),
                Text('Qty: ${product['quantity']}'),
                ElevatedButton(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    textStyle: TextStyle(fontSize: 12),
                  ),
                  child: Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartPage({super.key, required this.cart});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void _incrementQuantity(Map<String, dynamic> product) {
    setState(() {
      product['quantity']++;
    });
  }

  void _decrementQuantity(Map<String, dynamic> product) {
    setState(() {
      if (product['quantity'] > 1) {
        product['quantity']--;
      } else {
        widget.cart.remove(product);
      }
    });
  }

  double getTotalAmount() {
    return widget.cart
        .fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // int getTotalQuantity() {
  //   return widget.cart.fold(0, (sum, item) => sum + item['quantity']);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.cart.length,
                itemBuilder: (context, index) {
                  final product = widget.cart[index];
                  return _buildCartItem(product);
                },
              ),
            ),
            //Text('Total Quantity: ${getTotalQuantity()}'),
            Text('Total Amount: \$${getTotalAmount().toStringAsFixed(2)}'),
            ElevatedButton(
              onPressed: () {
                // Handle checkout
              },
              child: Text('Proceed to Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> product) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Price: \$${product['price']}'),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity: ${product['quantity']}'),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _decrementQuantity(product),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _incrementQuantity(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
