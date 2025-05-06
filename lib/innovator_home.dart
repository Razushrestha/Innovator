import 'package:flutter/material.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/utils/custom_drawer.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class Homepage extends StatefulWidget {
  
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Initialize mq for global use

    return Scaffold(
            drawer: const CustomDrawer(),

      body: Stack(
        children: [
          Inner_HomePage(),
          
          // Add the floating menu widget
          FloatingMenuWidget(),
        ],
      ),
    );
  }
}