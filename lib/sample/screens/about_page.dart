import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('About the App'),
            _buildSectionContent(
              'This app is designed to provide users with a comprehensive platform for community engagement, content sharing, and more. Our goal is to create a user-friendly experience that connects people and fosters meaningful interactions.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Development Team'),
            _buildSectionContent(
              'Our app is developed by a dedicated team of professionals who are passionate about technology and innovation. We strive to deliver the best possible experience for our users.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Contact Information'),
            _buildSectionContent(
              'If you have any questions, feedback, or need support, please feel free to reach out to us:\n\nEmail: support@example.com\nPhone: +1 234 567 890\nAddress: 123 Main St, City, Country',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Copyright Information'),
            _buildSectionContent(
              '© 2023 Your Company Name. All rights reserved. Unauthorized duplication or distribution of this app or its content is strictly prohibited.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Privacy Policy'),
            _buildSectionContent(
              'We are committed to protecting your privacy. Our privacy policy outlines how we collect, use, and safeguard your information. Please review our privacy policy for more details.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Terms of Service'),
            _buildSectionContent(
              'By using this app, you agree to our terms of service. Please review our terms of service for more details on your rights and responsibilities as a user.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[700],
      ),
    );
  }
}
