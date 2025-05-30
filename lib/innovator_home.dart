import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/screens/chatrrom/controller/chatlist_controller.dart';
import 'package:innovator/utils/custom_drawer.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with SingleTickerProviderStateMixin {
  final ChatListController chatController = Get.put(ChatListController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Check for app updates when the widget initializes
    _checkForUpdate();
  }

   Future<void> _checkForUpdate() async {
    log('Checking for Update!');
    await InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          log('Update available!');
          _update();
        }
      });
    }).catchError((error) {
      log(error.toString());
    });
  }

  void _update() async {
    log('Updating');
    await InAppUpdate.startFlexibleUpdate();
    InAppUpdate.completeFlexibleUpdate().then((_) {}).catchError((error) {
      log(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // drawer: const CustomDrawer(),
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