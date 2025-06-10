import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/main.dart';
import 'package:innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/screens/Feed/Video_Feed.dart';
import 'package:innovator/screens/chatrrom/controller/chatlist_controller.dart';
import 'package:innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/widget/Feed&Post.dart';
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
    try {
      log('Checking for Update!');
      
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        log('Update available!');
        
        // Check if immediate update is required (for critical updates)
        if (info.immediateUpdateAllowed) {
          _performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          _performFlexibleUpdate();
        }
      } else {
        log('No update available');
      }
    } catch (error) {
      log('Error checking for update: $error');
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      log('Starting immediate update');
      await InAppUpdate.performImmediateUpdate();
    } catch (error) {
      log('Immediate update failed: $error');
    }
  }

  Future<void> _performFlexibleUpdate() async {
    try {
      log('Starting flexible update');
      await InAppUpdate.startFlexibleUpdate();
      
      // Listen for download completion
      InAppUpdate.completeFlexibleUpdate().then((_) {
        log('Flexible update completed');
        _showUpdateCompletedSnackbar();
      }).catchError((error) {
        log('Error completing flexible update: $error');
      });
    } catch (error) {
      log('Flexible update failed: $error');
    }
  }

  void _showUpdateCompletedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update downloaded. Restart app to apply changes.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
        duration: Duration(seconds: 10),
      ),
    );
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
          Positioned(
            top: mq.height * 0.01,
            right: mq.width *.03,            
            child: FeedToggleButton(onToggle: (bool isPost) { Navigator.push(context, MaterialPageRoute(builder: (_) => VideoFeedPage()));},))
        ],
      ),
    );
  }
}