import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection(
            context,
            title: 'Account Settings',
            settings: [
              _buildSettingsTile(
                context,
                icon: Icons.person,
                title: 'Profile',
                onTap: () {
                  // Navigate to Profile settings
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.lock,
                title: 'Change Password',
                onTap: () {
                  // Navigate to Change Password settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            title: 'Notification Settings',
            settings: [
              _buildSettingsTile(
                context,
                icon: Icons.notifications,
                title: 'Push Notifications',
                onTap: () {
                  // Navigate to Push Notifications settings
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.email,
                title: 'Email Notifications',
                onTap: () {
                  // Navigate to Email Notifications settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            title: 'Privacy Settings',
            settings: [
              _buildSettingsTile(
                context,
                icon: Icons.lock_outline,
                title: 'Privacy Policy',
                onTap: () {
                  // Navigate to Privacy Policy settings
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.security,
                title: 'Security',
                onTap: () {
                  // Navigate to Security settings
                },
              ),
            ],
          ),
          _buildSettingsSection(
            context,
            title: 'App Settings',
            settings: [
              _buildSettingsTile(
                context,
                icon: Icons.language,
                title: 'Language',
                onTap: () {
                  // Navigate to Language settings
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.info,
                title: 'About',
                onTap: () {
                  // Navigate to About settings
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context,
      {required String title, required List<Widget> settings}) {
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
            ...settings,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: onTap,
    );
  }
}
