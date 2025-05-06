import 'package:flutter/material.dart';
import 'package:innovator/screens/Course/bookscreen.dart';
import 'package:innovator/screens/Course/favourite_screen.dart';
import 'package:innovator/screens/Course/profile_screen.dart';
import 'package:innovator/screens/Course/tabbar.dart';


class Course_Homepage extends StatefulWidget {
  const Course_Homepage({super.key});

  @override
  State<Course_Homepage> createState() => _Course_HomepageState();
}

class _Course_HomepageState extends State<Course_Homepage> {
  int currentIndex = 0;
  final List<Widget> screens = [
    TabBarScreen(),
    FavouriteScreen(),
    Bookscreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: screens[currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, Icons.home_outlined, 'Home'),
                _buildNavItem(
                    1, Icons.star, Icons.star_border_rounded, 'Favourite'),
                _buildNavItem(
                    2, Icons.menu_book, Icons.menu_book_outlined, 'Course'),
                _buildNavItem(
                    3, Icons.person, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Color(0xff5F73F3),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Color(0xff5F73F3),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
