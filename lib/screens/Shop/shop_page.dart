import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> categories = [
    'All',
    'IoT Devices',
    'Robots',
    'Components',
    'Kits',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       //  SizedBox(height: 20),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                margin: EdgeInsets.only(top: 5, bottom: 20),
                width: MediaQuery.of(context).size.width * 0.6,
                //height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextFormField(
                  onTap: () {},
                  readOnly: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, size: 30),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(1.0),
              // padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text("Category"),
                  value: null, // Add a state variable for selected value
                  items:
                      [
                        'All',
                        'IoT Devices',
                        'Robots',
                        'Components',
                        'Kits',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    // Handle dropdown selection
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                // Cart functionality
              },
            ),
          ],
        ),
        // Row(
        //   //mainAxisAlignment: MainAxisAlignment.end,
        //   children: [
        //    TextField(
        //       decoration: InputDecoration(
        //         hintText: 'Search',
        //         prefixIcon: const Icon(Icons.search),
        //         border: OutlineInputBorder(
        //           borderRadius: BorderRadius.circular(12),
        //           borderSide: BorderSide(
        //             color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        //           ),
        //         ),
        //         filled: true,
        //         fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        //       ),
        //       onChanged: (value) {
        //         // Search functionality
        //       },
        //     ),
        //     //const SizedBox(width: 16),
        //   // IconButton(
        //   //   icon: const Badge(
        //   //     label: Text('3'),
        //   //     child: Icon(Icons.shopping_cart),
        //   //   ),
        //   //   onPressed: () {
        //   //     // Cart functionality
        //   //   },
        //   // ),
        // ],),
        // Featured banner
        Container(
          // height: mq.height * 0.25,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  'placeholder.png', // Replace with actual robot image
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      width: 140,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.smart_toy,
                        size: 80,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'NEW ARRIVAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smart Home\nRobot Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Categories tabs
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            tabs: categories.map((category) => Tab(text: category)).toList(),
          ),
        ),

        // Products grid
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children:
                categories
                    .map((category) => ProductGrid(category: category))
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class ProductGrid extends StatelessWidget {
  final String category;

  const ProductGrid({Key? key, required this.category}) : super(key: key);

  List<Product> getFilteredProducts() {
    if (category == 'All') {
      return demoProducts;
    } else {
      return demoProducts
          .where((product) => product.category == category)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return filteredProducts.isEmpty
        ? const Center(child: Text('No products in this category yet'))
        : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: filteredProducts[index]);
          },
        );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: isDarkMode ? Colors.grey[850] : Colors.orange,
                  child: Stack(
                    children: [
                      Center(
                        child:
                            product.imageUrl != null
                                ? Image.asset(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      getIconForCategory(product.category),
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  },
                                )
                                : Icon(
                                  getIconForCategory(product.category),
                                  size: 60,
                                  color: Colors.white,
                                ),
                      ),
                      if (product.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
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
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minHeight: 32,
                            minWidth: 32,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            // Add to cart functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
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

  IconData getIconForCategory(String category) {
    switch (category) {
      case 'IoT Devices':
        return Icons.devices;
      case 'Robots':
        return Icons.smart_toy;
      case 'Components':
        return Icons.memory;
      case 'Kits':
        return Icons.science;
      default:
        return Icons.devices_other;
    }
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {
              // Add to wishlist
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    child: Center(
                      child:
                          product.imageUrl != null
                              ? Image.asset(
                                product.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getIconForCategory(product.category),
                                    size: 100,
                                    color: Colors.grey.withOpacity(0.3),
                                  );
                                },
                              )
                              : Icon(
                                _getIconForCategory(product.category),
                                size: 100,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                    ),
                  ),

                  // Product information
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviews} reviews)',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    product.inStock ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.inStock ? 'In Stock' : 'Out of Stock',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'About this product',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.fullDescription,
                          style: TextStyle(
                            height: 1.5,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Specifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...product.specifications.entries.map(
                          (spec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    spec.key,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                Expanded(child: Text(spec.value)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Related Products',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                demoProducts.length > 5
                                    ? 5
                                    : demoProducts.length,
                            itemBuilder: (context, index) {
                              final relatedProduct = demoProducts[index];
                              if (relatedProduct.id == product.id) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[850]
                                                  : Colors.grey[100],
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                        ),
                                        child: Center(
                                          child:
                                              relatedProduct.imageUrl != null
                                                  ? Image.asset(
                                                    relatedProduct.imageUrl!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(
                                                        _getIconForCategory(
                                                          relatedProduct
                                                              .category,
                                                        ),
                                                        size: 40,
                                                        color: Colors.grey
                                                            .withOpacity(0.3),
                                                      );
                                                    },
                                                  )
                                                  : Icon(
                                                    _getIconForCategory(
                                                      relatedProduct.category,
                                                    ),
                                                    size: 40,
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                  ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            relatedProduct.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${relatedProduct.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with add to cart button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {},
                          iconSize: 18,
                        ),
                        const SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                          iconSize: 18,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          product.inStock
                              ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} added to cart',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'IoT Devices':
        return Icons.devices;
      case 'Robots':
        return Icons.smart_toy;
      case 'Components':
        return Icons.memory;
      case 'Kits':
        return Icons.science;
      default:
        return Icons.devices_other;
    }
  }
}

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         const SizedBox(height: 24),
//         // User info card
//         Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.primary,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 36,
//                 backgroundColor: Colors.white.withOpacity(0.2),
//                 child: const Icon(
//                   Icons.person,
//                   size: 36,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'John Doe',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 24,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'john.doe@example.com',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.edit, color: Colors.white),
//                 onPressed: () {
//                   // Edit profile
//                 },
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),

//         // Orders section
//         const Text(
//           'My Orders',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               _buildProfileListTile(
//                 context,
//                 Icons.shopping_bag,
//                 'Order History',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.local_shipping,
//                 'Track Order',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.reviews,
//                 'Reviews',
//                 onTap: () {},
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),

//         // Account section
//         const Text(
//           'Account Settings',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               _buildProfileListTile(
//                 context,
//                 Icons.person,
//                 'Personal Information',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.location_on,
//                 'Addresses',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.payment,
//                 'Payment Methods',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.notifications,
//                 'Notifications',
//                 onTap: () {},
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),

//         // Other section
//         const Text(
//           'Other',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               _buildProfileListTile(
//                 context,
//                 Icons.help,
//                 'Help & Support',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.settings,
//                 'Settings',
//                 onTap: () {},
//               ),
//               const Divider(height: 1),
//               _buildProfileListTile(
//                 context,
//                 Icons.logout,
//                 'Logout',
//                 onTap: () {},
//                 textColor: Colors.red,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 32),
//       ],
//     );
//   }

//   Widget _buildProfileListTile(
//     BuildContext context,
//     IconData icon,
//     String title, {
//     required VoidCallback onTap,
//     Color? textColor,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: textColor ?? Theme.of(context).colorScheme.primary),
//       title: Text(
//         title, style: TextStyle(
//           color: textColor,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       trailing: const Icon(Icons.chevron_right),
//       onTap: onTap,
//     );
//   }
// }

// Model classes
class Product {
  final int id;
  final String name;
  final String description;
  final String fullDescription;
  final double price;
  final String category;
  final String? imageUrl;
  final double rating;
  final int reviews;
  final bool inStock;
  final bool isNew;
  final Map<String, String> specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.fullDescription,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.inStock,
    this.isNew = false,
    required this.specifications,
  });
}

// Demo data
final List<Product> demoProducts = [
  Product(
    id: 1,
    name: 'Smart Home Robot',
    description: 'AI-powered home assistant robot',
    fullDescription:
        'Meet your new home companion! This AI-powered smart robot connects to your home network and integrates with your existing smart devices. With advanced voice recognition, facial recognition, and learning capabilities, it adapts to your preferences and routines. Features include autonomous navigation, automatic docking for charging, video calls, home monitoring, and entertainment functions. Perfect for families, tech enthusiasts, or anyone looking to step into the future of smart home technology.',
    price: 499.99,
    category: 'Robots',
    imageUrl: null, // Replace with actual image path
    rating: 4.8,
    reviews: 245,
    inStock: true,
    isNew: true,
    specifications: {
      'Dimensions': '30cm x 20cm x 20cm',
      'Weight': '2.5kg',
      'Battery': '5000mAh (8 hours runtime)',
      'Camera': '1080p HD with 120° field of view',
      'Connectivity': 'WiFi 6, Bluetooth 5.0',
      'Compatability': 'Works with Alexa, Google Home, Apple HomeKit',
      'CPU': 'Quad-core 2.5GHz',
      'RAM': '4GB',
      'Storage': '64GB',
    },
  ),
  Product(
    id: 2,
    name: 'IoT Smart Thermostat',
    description: 'Energy-saving smart temperature control',
    fullDescription:
        'Transform your home climate control with our premium IoT Smart Thermostat. This device learns your schedule and preferences to automatically adjust heating and cooling for optimal comfort and energy savings. The intuitive touchscreen interface and mobile app make it easy to monitor and control your home temperature from anywhere. Features include geofencing, which adjusts settings based on your location, detailed energy consumption reports, and compatibility with major smart home ecosystems. Save up to 23% on yearly heating and cooling costs.',
    price: 129.99,
    category: 'IoT Devices',
    imageUrl: null, // Replace with actual image path
    rating: 4.7,
    reviews: 189,
    inStock: true,
    specifications: {
      'Dimensions': '10cm x 10cm x 2.5cm',
      'Display': '2.8" Color touchscreen',
      'Sensors': 'Temperature, Humidity, Motion, Ambient light',
      'Connectivity': 'WiFi, Bluetooth',
      'Power': '24V AC or battery-powered',
      'Compatability': 'Works with Alexa, Google Home, Apple HomeKit',
      'Temperature Range': '0-35°C',
    },
  ),
  Product(
    id: 3,
    name: 'Arduino Robotics Kit',
    description: 'Complete DIY robotics learning kit',
    fullDescription:
        'Start your robotics journey with this comprehensive Arduino-based robotics kit. Perfect for beginners and intermediate makers, this kit includes everything you need to build and program your own robot. The set comes with a detailed step-by-step instruction manual and access to online video tutorials. You\'ll learn about electronics, programming, mechanics, and problem-solving while creating a functional robot that can navigate obstacles, follow lines, and be controlled wirelessly via a smartphone app. No prior experience necessary—just bring your curiosity!',
    price: 89.99,
    category: 'Kits',
    imageUrl: null, // Replace with actual image path
    rating: 4.5,
    reviews: 123,
    inStock: true,
    specifications: {
      'Components':
          '1x Arduino UNO, 2x DC Motors, 1x Motor Driver, 1x Ultrasonic Sensor, 1x Bluetooth Module',
      'Material': 'Acrylic chassis, metal components',
      'Programming': 'Arduino IDE (C/C++)',
      'Power': '4x AA Batteries (not included)',
      'Assembly Time': 'Approx. 2-3 hours',
      'Difficulty Level': 'Beginner to Intermediate',
      'Age Range': '12+ years',
    },
  ),
  Product(
    id: 4,
    name: 'Raspberry Pi 5',
    description: 'Latest single-board computer for IoT projects',
    fullDescription:
        'The Raspberry Pi 5 raises the bar for single-board computing with significantly improved performance and capabilities. Featuring a powerful quad-core processor, enhanced GPU, and increased RAM options, this tiny computer packs a serious punch. Perfect for IoT projects, home automation, retro gaming, media centers, learning programming, and countless DIY projects. The familiar form factor maintains compatibility with most existing Pi accessories while adding new features like dual 4K display support, improved thermal management, and upgraded USB ports. Get started with endless possibilities in the palm of your hand.',
    price: 59.99,
    category: 'Components',
    imageUrl: null, // Replace with actual image path
    rating: 4.9,
    reviews: 320,
    inStock: false,
    specifications: {
      'Processor': 'Quad-core Cortex-A76 2.4GHz',
      'RAM': '4GB/8GB LPDDR4',
      'GPU': 'VideoCore VII',
      'Connectivity': 'WiFi 6, Bluetooth 5.0, Gigabit Ethernet',
      'Ports': '2x USB 3.0, 2x USB 2.0, 2x micro-HDMI (4K@60Hz), GPIO pins',
      'Power': '5V DC via USB-C',
      'Dimensions': '85mm x 56mm x 21mm',
    },
  ),
  Product(
    id: 5,
    name: 'Smart Security Camera',
    description: '1080p wireless security with motion detection',
    fullDescription:
        'Keep your home or business secure with our advanced Smart Security Camera. This weatherproof, wireless camera delivers crystal-clear 1080p HD video day and night. With intelligent motion detection, it can distinguish between people, animals, and vehicles to send relevant alerts directly to your smartphone. Two-way audio allows you to communicate with visitors or deter intruders. Cloud storage options and local SD card backup ensure your footage is always available when you need it. Easy installation and an intuitive app make this the perfect security solution for any property.',
    price: 79.99,
    category: 'IoT Devices',
    imageUrl: null, // Replace with actual image path
    rating: 4.6,
    reviews: 215,
    inStock: true,
    specifications: {
      'Resolution': '1080p Full HD',
      'Field of View': '130° wide angle',
      'Night Vision': 'Infrared LEDs, up to 30ft',
      'Audio': 'Built-in mic and speaker',
      'Storage': 'Cloud (subscription) or microSD (up to 128GB)',
      'Power': 'Battery (rechargeable, 6-month life) or wired',
      'Weather Rating': 'IP65 waterproof',
      'Connectivity': 'WiFi 2.4GHz',
    },
  ),
  Product(
    id: 6,
    name: 'Drone Programming Kit',
    description: 'Learn to program autonomous drones',
    fullDescription:
        'Take to the skies with our comprehensive Drone Programming Kit. This educational package includes a fully assembled quadcopter drone with programmable flight controller, sensors, and camera. The included curriculum guides you through the basics of drone physics, programming autonomous flight patterns, computer vision, and even machine learning applications for drones. Perfect for STEM education, hobbyists wanting to go beyond manual controls, or professionals looking to expand their skills. The drone comes with safety features like propeller guards and emergency landing protocols to ensure a safe learning experience.',
    price: 249.99,
    category: 'Kits',
    imageUrl: null, // Replace with actual image path
    rating: 4.4,
    reviews: 68,
    inStock: true,
    isNew: true,
    specifications: {
      'Drone Size': '25cm x 25cm x 10cm',
      'Flight Time': '15 minutes per battery',
      'Camera': '720p with stabilization',
      'Programming': 'Python, Blockly visual programming',
      'Sensors': 'Accelerometer, gyroscope, barometer, optical flow',
      'Connectivity': 'WiFi direct, Bluetooth',
      'Max Range': '100 meters',
      'Assembly Required': 'No, ready to fly',
    },
  ),
  Product(
    id: 7,
    name: 'IoT Starter Kit',
    description: 'Complete package to begin IoT development',
    fullDescription:
        'Launch your IoT journey with our comprehensive Starter Kit. This all-in-one package contains everything needed to create your first connected devices. The kit includes an ESP32 development board, breadboard, jumper wires, resistors, capacitors, LEDs, various sensors (temperature, humidity, motion, light), relay modules, and an OLED display. The detailed guidebook walks you through 15 progressive projects, from basic sensor reading to creating your own smart home devices. All components come in a durable storage case to keep everything organized. No prior experience necessary!',
    price: 69.99,
    category: 'Kits',
    imageUrl: null, // Replace with actual image path
    rating: 4.7,
    reviews: 156,
    inStock: true,
    specifications: {
      'Main Board': 'ESP32 (WiFi + Bluetooth)',
      'Sensors': '10+ different types included',
      'Projects': '15 guided projects with source code',
      'Programming': 'Arduino IDE, MicroPython support',
      'Power': 'USB powered or battery (not included)',
      'Skill Level': 'Beginner to Intermediate',
      'Documentation': 'Printed manual + online resources',
    },
  ),
  Product(
    id: 8,
    name: 'Smart Plant Monitor',
    description: 'IoT device for monitoring plant health',
    fullDescription:
        'Give your plants a voice with our Smart Plant Monitor. This innovative IoT device tracks soil moisture, light levels, temperature, and nutrient concentrations to ensure your plants thrive. The sleek, waterproof probe sits discreetly in the soil while continuously monitoring conditions and sending data to the companion app. Receive notifications when your plants need water, fertilizer, or different light conditions. The app maintains a history of readings and provides care recommendations specific to your plant species. Perfect for both beginning gardeners and plant enthusiasts who want to optimize growing conditions.',
    price: 39.99,
    category: 'IoT Devices',
    imageUrl: null, // Replace with actual image path
    rating: 4.5,
    reviews: 92,
    inStock: true,
    specifications: {
      'Sensors': 'Moisture, light, temperature, conductivity (nutrients)',
      'Battery Life': 'Up to 6 months on a single charge',
      'Connectivity': 'Bluetooth LE, WiFi hub optional',
      'Water Resistance': 'IP67 rated',
      'App Compatibility': 'iOS 12+ and Android 8+',
      'Plant Database': '5000+ plant species with care info',
      'Dimensions': '12cm probe length, 3cm diameter',
    },
  ),
  Product(
    id: 9,
    name: 'Humanoid Robot Arm',
    description: 'Programmable 6-axis robotic arm',
    fullDescription:
        'Bring industrial-grade robotics to your desktop with this 6-axis Humanoid Robot Arm. Designed for education, research, and hobby applications, this arm mimics human-like movement with precision and repeatability. The arm can be programmed using Python, C++, or our visual programming interface. Applications include pick-and-place operations, light assembly tasks, drawing, and education in robotics concepts. The open architecture allows for customization and expansion with additional tools and sensors. Each servo motor features position feedback and overload protection for safety and reliability.',
    price: 329.99,
    category: 'Robots',
    imageUrl: null, // Replace with actual image path
    rating: 4.8,
    reviews: 47,
    inStock: true,
    specifications: {
      'Degrees of Freedom': '6-axis movement',
      'Max Payload': '250g',
      'Reach': '350mm maximum',
      'Precision': '±0.2mm repeatability',
      'Control': 'USB, WiFi, or Bluetooth',
      'Programming': 'Python, C++, Blockly visual interface',
      'Power': '12V DC adapter (included)',
      'Material': 'Aluminum alloy and ABS plastic',
    },
  ),
  Product(
    id: 10,
    name: 'Motor Driver Module',
    description: 'H-bridge DC motor controller for robots',
    fullDescription:
        'Control DC motors with precision using our dual H-bridge Motor Driver Module. This compact but powerful board allows you to independently control the speed and direction of two DC motors or one stepper motor. Perfect for robotics projects, automated systems, or any application requiring motor control. The module features thermal and overcurrent protection, status LEDs, and logic-level compatibility with Arduino, Raspberry Pi, and other microcontrollers. Screw terminals make connecting motors and power supply easy and secure. An essential component for any robotics toolkit.',
    price: 12.99,
    category: 'Components',
    imageUrl: null, // Replace with actual image path
    rating: 4.6,
    reviews: 203,
    inStock: true,
    specifications: {
      'Motor Channels': '2 DC motors or 1 stepper motor',
      'Max Current': '2A per channel (3A peak)',
      'Voltage Range': '5-35V DC for motors, 3.3-5V for logic',
      'Control Interface': 'PWM input for speed control',
      'Protection': 'Thermal shutdown, overcurrent protection',
      'Dimensions': '43mm x 43mm x 15mm',
      'Mounting Holes': '4x M3 mounting holes',
    },
  ),
];
