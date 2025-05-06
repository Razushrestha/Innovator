import 'package:flutter/material.dart';

class WebDevelopmentScreen extends StatelessWidget {
  const WebDevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Web Development Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            buildCourseCard(
              'Full Stack Development',
              '15 lessons',
              Colors.lightBlue,
            ),
            SizedBox(height: 15),
            buildCourseCard(
              'JavaScript Mastery',
              '12 lessons',
              Colors.lightBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCourseCard(String title, String lessons, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(lessons),
          SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.play_circle_outline, color: color),
              SizedBox(width: 5),
              Text('Start Learning', style: TextStyle(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
