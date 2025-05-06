import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEB6B46), // corrected hex code
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    // backgroundImage: AssetImage(
                    //   'assets/profile.jpg',
                    // ), // make sure to add a valid image
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome, Razu!',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Innovator',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDrawerTile(Icons.book, 'Courses', () {}),
          _buildDrawerTile(Icons.star, 'Messages', () {}),
          _buildDrawerTile(Icons.message, 'Profile', () {}),
          _buildDrawerTile(Icons.settings, 'Settings', () {}),
          _buildDrawerTile(Icons.privacy_tip_rounded, 'Privacy&Policy', () {}),
          _buildDrawerTile(Icons.question_answer_rounded, 'F&Q', () {}),
          const Divider(thickness: 1, indent: 20, endIndent: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Text(
              'Innovator App v1.0\nPowered by Nepatronix',
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFEB6B46)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFFEB6B46).withOpacity(0.1),
    );
  }
}
