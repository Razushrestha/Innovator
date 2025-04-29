import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHelpSection(
            context,
            title: 'Getting Started',
            content:
                'Learn how to get started with our app and make the most out of its features.',
          ),
          _buildHelpSection(
            context,
            title: 'Account Management',
            content:
                'Find out how to manage your account settings, update your profile, and more.',
          ),
          _buildHelpSection(
            context,
            title: 'Privacy & Security',
            content:
                'Understand our privacy policies and learn how to keep your account secure.',
          ),
          _buildHelpSection(
            context,
            title: 'Troubleshooting',
            content:
                'Get help with common issues and find solutions to your problems.',
          ),
          _buildHelpSection(
            context,
            title: 'Contact Us',
            content:
                'If you need further assistance, feel free to reach out to our support team.',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context,
      {required String title, required String content}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
