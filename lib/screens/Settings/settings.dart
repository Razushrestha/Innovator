import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Blocked/BlockedUser.dart';
import 'package:innovator/screens/Profile/Edit_Profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innovator/Authorization/change_pwd.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // App theme color
  final Color primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  
  // Settings state variables
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool privateAccount = false;
  bool allowTagging = true;
  bool showOnlineStatus = true;
  bool darkMode = false;
  bool autoPlayVideos = true;
  bool saveToGallery = false;
  String selectedLanguage = 'English';
  
  // Loading state
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        pushNotifications = prefs.getBool('pushNotifications') ?? true;
        emailNotifications = prefs.getBool('emailNotifications') ?? false;
        privateAccount = prefs.getBool('privateAccount') ?? false;
        allowTagging = prefs.getBool('allowTagging') ?? true;
        showOnlineStatus = prefs.getBool('showOnlineStatus') ?? true;
        darkMode = prefs.getBool('darkMode') ?? false;
        autoPlayVideos = prefs.getBool('autoPlayVideos') ?? true;
        saveToGallery = prefs.getBool('saveToGallery') ?? false;
        selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
        _isLoading = false;
      });
    } catch (e) {
      // Handle error loading settings
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Failed', 'Failed to Load Settings', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  // Save individual setting
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
      
      // Show success feedback
            Get.snackbar('Saved', 'All Settings Saved Successfully', backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      // Handle save error
      Get.snackbar('Failed', 'Failed to Save Settings', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  // Save all settings at once
  Future<void> _saveAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool('pushNotifications', pushNotifications),
        prefs.setBool('emailNotifications', emailNotifications),
        prefs.setBool('privateAccount', privateAccount),
        prefs.setBool('allowTagging', allowTagging),
        prefs.setBool('showOnlineStatus', showOnlineStatus),
        prefs.setBool('darkMode', darkMode),
        prefs.setBool('autoPlayVideos', autoPlayVideos),
        prefs.setBool('saveToGallery', saveToGallery),
        prefs.setString('selectedLanguage', selectedLanguage),
      ]);
      Get.snackbar('Saved', 'All Settings Saved Successfully', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', 'Failed to Save Settings', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  // Reset settings to default
  Future<void> _resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all settings
      await prefs.remove('pushNotifications');
      await prefs.remove('emailNotifications');
      await prefs.remove('privateAccount');
      await prefs.remove('allowTagging');
      await prefs.remove('showOnlineStatus');
      await prefs.remove('darkMode');
      await prefs.remove('autoPlayVideos');
      await prefs.remove('saveToGallery');
      await prefs.remove('selectedLanguage');
      
      // Reset to defaults
      setState(() {
        pushNotifications = true;
        emailNotifications = false;
        privateAccount = false;
        allowTagging = true;
        showOnlineStatus = true;
        darkMode = false;
        autoPlayVideos = true;
        saveToGallery = false;
        selectedLanguage = 'English';
      });
      
      Get.snackbar('Reset', 'Settings Reset to Default', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', 'Failed to Reset', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   // Save all settings button
        //   IconButton(
        //     icon: const Icon(Icons.save),
        //     onPressed: _saveAllSettings,
        //     tooltip: 'Save All Settings',
        //   ),
        //   // Reset settings button
        //   PopupMenuButton<String>(
        //     icon: const Icon(Icons.more_vert),
        //     onSelected: (value) {
        //       if (value == 'reset') {
        //         _showResetDialog();
        //       }
        //     },
        //     itemBuilder: (context) => [
        //       const PopupMenuItem(
        //         value: 'reset',
        //         child: Row(
        //           children: [
        //             Icon(Icons.restore, color: Colors.red),
        //             SizedBox(width: 8),
        //             Text('Reset to Default'),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionCard(
              title: 'Account',
              icon: Icons.person,
              children: [
                _buildSettingsTile(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen())),
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                  ),
                ),
                _buildSwitchTile(
                  icon: Icons.privacy_tip,
                  title: 'Private Account',
                  subtitle: 'Only followers can see your posts',
                  value: privateAccount,
                  onChanged: (value) {
                    setState(() => privateAccount = value);
                    _saveSetting('privateAccount', value);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Privacy & Security Section
            _buildSectionCard(
              title: 'Privacy & Security',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  icon: Icons.visibility,
                  title: 'Show Online Status',
                  subtitle: 'Let others see when you\'re active',
                  value: showOnlineStatus,
                  onChanged: (value) {
                    setState(() => showOnlineStatus = value);
                    _saveSetting('showOnlineStatus', value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.local_offer,
                  title: 'Allow Tagging',
                  subtitle: 'Others can tag you in posts',
                  value: allowTagging,
                  onChanged: (value) {
                    setState(() => allowTagging = value);
                    _saveSetting('allowTagging', value);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked accounts',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlockedUsersScreen ())),
                ),
                // _buildSettingsTile(
                //   icon: Icons.report,
                //   title: 'Report a Problem',
                //   subtitle: 'Get help or report issues',
                //   onTap: () => _navigateToScreen('Report Problem'),
                // ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notifications Section
            // _buildSectionCard(
            //   title: 'Notifications',
            //   icon: Icons.notifications,
            //   children: [
            //     _buildSwitchTile(
            //       icon: Icons.push_pin,
            //       title: 'Push Notifications',
            //       subtitle: 'Receive notifications on your device',
            //       value: pushNotifications,
            //       onChanged: (value) {
            //         setState(() => pushNotifications = value);
            //         _saveSetting('pushNotifications', value);
            //       },
            //     ),
            //     _buildSwitchTile(
            //       icon: Icons.email,
            //       title: 'Email Notifications',
            //       subtitle: 'Receive updates via email',
            //       value: emailNotifications,
            //       onChanged: (value) {
            //         setState(() => emailNotifications = value);
            //         _saveSetting('emailNotifications', value);
            //       },
            //     ),
            //     _buildSettingsTile(
            //       icon: Icons.tune,
            //       title: 'Notification Preferences',
            //       subtitle: 'Customize what notifications you receive',
            //       onTap: () => _navigateToScreen('Notification Preferences'),
            //     ),
            //   ],
            // ),
            
            // const SizedBox(height: 16),
            
            // // Media & Storage Section
            // _buildSectionCard(
            //   title: 'Media & Storage',
            //   icon: Icons.photo_library,
            //   children: [
            //     _buildSwitchTile(
            //       icon: Icons.play_circle,
            //       title: 'Auto-play Videos',
            //       subtitle: 'Videos play automatically in feed',
            //       value: autoPlayVideos,
            //       onChanged: (value) {
            //         setState(() => autoPlayVideos = value);
            //         _saveSetting('autoPlayVideos', value);
            //       },
            //     ),
            //     _buildSwitchTile(
            //       icon: Icons.download,
            //       title: 'Save to Gallery',
            //       subtitle: 'Automatically save posted media',
            //       value: saveToGallery,
            //       onChanged: (value) {
            //         setState(() => saveToGallery = value);
            //         _saveSetting('saveToGallery', value);
            //       },
            //     ),
            //     _buildSettingsTile(
            //       icon: Icons.storage,
            //       title: 'Storage & Data',
            //       subtitle: 'Manage app storage usage',
            //       onTap: () => _navigateToScreen('Storage Settings'),
            //     ),
            //   ],
            // ),
            
            // const SizedBox(height: 16),
            
            // // App Preferences Section
            // _buildSectionCard(
            //   title: 'App Preferences',
            //   icon: Icons.settings,
            //   children: [
            //     _buildSwitchTile(
            //       icon: Icons.dark_mode,
            //       title: 'Dark Mode',
            //       subtitle: 'Use dark theme',
            //       value: darkMode,
            //       onChanged: (value) {
            //         setState(() => darkMode = value);
            //         _saveSetting('darkMode', value);
            //       },
            //     ),
            //     _buildLanguageTile(),
            //     _buildSettingsTile(
            //       icon: Icons.font_download,
            //       title: 'Font Size',
            //       subtitle: 'Adjust text size',
            //       onTap: () => _navigateToScreen('Font Settings'),
            //     ),
            //   ],
            // ),
            
            // const SizedBox(height: 16),
            
            // // Support Section
            // _buildSectionCard(
            //   title: 'Support',
            //   icon: Icons.help,
            //   children: [
            //     _buildSettingsTile(
            //       icon: Icons.help_outline,
            //       title: 'Help Center',
            //       subtitle: 'Get help and support',
            //       onTap: () => _navigateToScreen('Help Center'),
            //     ),
            //     _buildSettingsTile(
            //       icon: Icons.info_outline,
            //       title: 'About',
            //       subtitle: 'App version and information',
            //       onTap: () => _navigateToScreen('About'),
            //     ),
            //     _buildSettingsTile(
            //       icon: Icons.rate_review,
            //       title: 'Rate App',
            //       subtitle: 'Rate us on the app store',
            //       onTap: () => _rateApp(),
            //     ),
            //   ],
            // ),
            
            // const SizedBox(height: 32),
            
            // // Save Settings Button
            // Container(
            //   width: double.infinity,
            //   margin: const EdgeInsets.only(bottom: 16),
            //   child: ElevatedButton.icon(
            //     onPressed: _saveAllSettings,
            //     icon: const Icon(Icons.save),
            //     label: const Text(
            //       'Save All Settings',
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: primaryColor,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //   ),
            // ),
            
            // // Logout Button
            // Center(
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: () => _showLogoutDialog(),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.red[600],
            //         foregroundColor: Colors.white,
            //         padding: const EdgeInsets.symmetric(vertical: 16),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: const Text(
            //         'Logout',
            //         style: TextStyle(
            //           fontSize: 16,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildLanguageTile() {
    return ListTile(
      leading: Icon(Icons.language, color: Colors.grey[600]),
      title: const Text(
        'Language',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        selectedLanguage,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      onTap: () => _showLanguageDialog(),
      contentPadding: EdgeInsets.zero,
    );
  }
  
  void _navigateToScreen(String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $screenName...'),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
    // Add your navigation logic here
    // Navigator.pushNamed(context, '/screenName');
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('French'),
            _buildLanguageOption('German'),
            _buildLanguageOption('Japanese'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      leading: Radio<String>(
        value: language,
        groupValue: selectedLanguage,
        onChanged: (value) {
          setState(() => selectedLanguage = value!);
          _saveSetting('selectedLanguage', value!);
          Navigator.pop(context);
        },
        activeColor: primaryColor,
      ),
    );
  }
  
  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening app store...'),
        duration: Duration(seconds: 1),
      ),
    );
    // Add your app store rating logic here
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add your logout logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}