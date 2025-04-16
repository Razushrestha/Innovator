import 'package:flutter/material.dart';
import 'package:innovator/Message_page.dart';
import 'package:innovator/books_pages.dart';

import 'favorites_page.dart';

import 'profile_page.dart';

class InnovatorHomePage extends StatelessWidget {
  const InnovatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Feed Section in the center
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                "Feed Section",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Right Side Vertical NavBar
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9A825), Color(0xFFF57F17)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavIcon(Icons.book, "Books", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BooksPage()),
                    );
                  }),
                  _buildNavIcon(Icons.star, "Favorites", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    );
                  }),

                  // Center floating button
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.orange),
                      tooltip: "Create",
                      onPressed: () {},
                    ),
                  ),

                  _buildNavIcon(Icons.message, "Messages", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesPage()),
                    );
                  }),
                  _buildNavIcon(Icons.person, "Profile", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 28),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
