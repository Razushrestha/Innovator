import 'package:flutter/material.dart';

class CourseDetails extends StatelessWidget {
  const CourseDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Course Details')),
      body: Center(
        child: Column(
          children: [
            Text('Course Title: Robotics for Beginners',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text(
                'Description: Learn the basics of robotics and build a functional robot.'),
          ],
        ),
      ),
    );
  }
}
