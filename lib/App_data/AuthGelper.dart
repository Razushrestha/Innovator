import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../App_data/App_data.dart';

class AuthHelper {
  static String? getCurrentUserId(BuildContext context, {bool redirectOnNull = true}) {
    final appData = Provider.of<AppData>(context, listen: false);
    final userId = appData.currentUserId;

    if (userId == null && redirectOnNull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Please log in.')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }

    return userId;
  }
}