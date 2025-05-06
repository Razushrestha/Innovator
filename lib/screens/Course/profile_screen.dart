import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xff5F73F3),
            child: Icon(CupertinoIcons.person, size: 60, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Elizabeth Holzer',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('Premium Member'),
        ],
      ),
    );
  }
}
