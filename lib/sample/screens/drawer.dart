import 'package:flutter/material.dart';
import 'package:innovator/sample/screens/about_page.dart';
import 'package:innovator/sample/screens/community.dart';
import 'package:innovator/sample/screens/course/course.dart';
import 'package:innovator/sample/screens/course_details.dart' as subscription;
import 'package:innovator/sample/screens/help_page.dart';
import 'package:innovator/sample/screens/notification_page.dart';
import 'package:innovator/sample/screens/profile_page.dart';
import 'package:innovator/sample/screens/settings_page.dart';
import 'package:innovator/sample/screens/shop_page.dart';
// Assuming you have a home page, import it
// import 'package:innovator/sample/screens/home_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.7),
            ),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerTile(context, Icons.home, 'Home', onTap: () {
            // Navigate to home page
            Navigator.pop(context);
            // Uncomment and adjust this if you have a specific home page
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => HomePage()),
            // );
          }),
          _buildDrawerTile(context, Icons.shopping_bag, 'Shop', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShopPage()),
            );
          }),
          _buildDrawerTile(context, Icons.book, 'Courses', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoursePage()),
            );
          }),
          _buildDrawerTile(context, Icons.person, 'Profile', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfilePage()),
            );
          }),
          _buildDrawerTile(context, Icons.notifications, 'Notifications',
              onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          }),
          _buildDrawerTile(context, Icons.help, 'Help', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelpPage()),
            );
          }),
          _buildDrawerTile(context, Icons.info, 'About', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutPage()),
            );
          }),
          _buildDrawerTile(context, Icons.subscriptions, 'Subscription',
              onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => subscription.SubscriptionPage()),
            );
          }),
          _buildDrawerTile(context, Icons.group, 'Community', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityPage()),
            );
          }),
          _buildDrawerTile(context, Icons.settings, 'Settings', onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, IconData icon, String title,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(title),
      ),
      onTap: onTap,
    );
  }
}