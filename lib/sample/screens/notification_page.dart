import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationCard(
            context,
            title: 'New Post',
            content: 'User1 has posted a new update. Check it out!',
            icon: Icons.post_add,
            onTap: () {
              // Navigate to the post or relevant page
            },
          ),
          _buildNotificationCard(
            context,
            title: 'Subscription Reminder',
            content:
                'Your subscription will expire in 5 days. Renew now to continue enjoying our services.',
            icon: Icons.subscriptions,
            onTap: () {
              // Navigate to the subscription page
            },
          ),
          _buildNotificationCard(
            context,
            title: 'App Update',
            content:
                'A new update is available. Update the app to enjoy the latest features and improvements.',
            icon: Icons.system_update,
            onTap: () {
              // Navigate to the app update page or prompt update
            },
          ),
          _buildNotificationCard(
            context,
            title: 'Friend Request',
            content: 'User2 has sent you a friend request.',
            icon: Icons.person_add,
            onTap: () {
              // Navigate to the friend requests page
            },
          ),
          _buildNotificationCard(
            context,
            title: 'New Message',
            content: 'You have received a new message from User3.',
            icon: Icons.message,
            onTap: () {
              // Navigate to the messages page
            },
          ),
          _buildNotificationCard(
            context,
            title: 'System Alert',
            content: 'Your account security settings need attention.',
            icon: Icons.warning,
            onTap: () {
              // Navigate to the security settings page
            },
          ),
          // Add more notifications here
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
