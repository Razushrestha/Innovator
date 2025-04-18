import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 50,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navigate to post detail
            },
            child: Image.network(
              'https://picsum.photos/500/500?random=explore$index',
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}