import 'package:flutter/material.dart';

class Bookscreen extends StatelessWidget {
  const Bookscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Color(0xff5F73F3)),
          SizedBox(height: 20),
          Text(
            'Your Course Book',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('No items in your course book yet.'),
        ],
      ),
    );
  }
}
