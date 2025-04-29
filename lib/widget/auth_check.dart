// lib/widgets/auth_check.dart

import 'package:flutter/material.dart';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:innovator/Authorization/Login.dart';

class AuthCheck extends StatelessWidget {
  final Widget child;
  
  const AuthCheck({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if token exists
    if (AppData().isAuthenticated) {
      return child;
    } else {
      // Redirect to login if not authenticated
      return LoginPage();
    }
  }
}