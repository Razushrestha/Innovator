import 'package:flutter/material.dart';

class SubscriptionPage extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SubscriptionCard(
                    title: 'Basic Plan',
                    price: '\$9.99/month',
                    features: ['Feature 1', 'Feature 2', 'Feature 3'],
                    gradientColors: [Colors.lightBlue, Colors.blue],
                  ),
                  SubscriptionCard(
                    title: 'Standard Plan',
                    price: '\$19.99/month',
                    features: [
                      'Feature 1',
                      'Feature 2',
                      'Feature 3',
                      'Feature 4'
                    ],
                    gradientColors: [Colors.blue, Colors.indigo],
                  ),
                  SubscriptionCard(
                    title: 'Premium Plan',
                    price: '\$29.99/month',
                    features: [
                      'Feature 1',
                      'Feature 2',
                      'Feature 3',
                      'Feature 4',
                      'Feature 5'
                    ],
                    gradientColors: [Colors.purple, Colors.deepPurple],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final List<Color> gradientColors;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 480,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Handle subscription logic
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'Subscribe',
                      style: TextStyle(
                        color: gradientColors.last,
                        fontSize: 18,
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
    );
  }
}
