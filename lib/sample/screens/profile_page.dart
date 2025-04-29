// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(),
            SizedBox(height: 20),
            UserInfoSection(),
            SizedBox(height: 20),
            SubscriptionSection(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
                'assets/images/profile_placeholder.png'), // Replace with actual profile picture path
          ),
          SizedBox(height: 10),
          Text(
            'John Doe', // Replace with actual user name
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'johndoe@example.com', // Replace with actual user email
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            UserInfoRow(
                title: 'Username',
                value: 'JohnDoe123'), // Replace with actual username
            UserInfoRow(
                title: 'Phone',
                value: '+1 234 567 890'), // Replace with actual phone number
            UserInfoRow(
                title: 'Address',
                value:
                    '123 Main St, City, Country'), // Replace with actual address
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return EditUserInfoDialog();
      },
    );
  }
}

class UserInfoRow extends StatelessWidget {
  final String title;
  final String value;

  const UserInfoRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({super.key});

  @override
  _SubscriptionSectionState createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  String _selectedPlan = 'Basic';
  final double _daysRemaining =
      0.5; // Example value, replace with actual calculation

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subscription Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditSubscriptionDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            SubscriptionRow(title: 'Plan', value: _selectedPlan),
            const SizedBox(height: 10),
            SubscriptionRow(
                title: 'Status', value: 'Active'), // Replace with actual status
            const SizedBox(height: 10),
            const Text(
              'Days Remaining',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: _daysRemaining,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return EditSubscriptionDialog(
          selectedPlan: _selectedPlan,
          onPlanChanged: (newPlan) {
            setState(() {
              _selectedPlan = newPlan;
            });
          },
        );
      },
    );
  }
}

class SubscriptionRow extends StatelessWidget {
  final String title;
  final String value;

  const SubscriptionRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class EditUserInfoDialog extends StatefulWidget {
  const EditUserInfoDialog({super.key});

  @override
  _EditUserInfoDialogState createState() => _EditUserInfoDialogState();
}

class _EditUserInfoDialogState extends State<EditUserInfoDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with current user information
    _usernameController.text = 'JohnDoe123'; // Replace with actual username
    _phoneController.text =
        '+1 234 567 890'; // Replace with actual phone number
    _addressController.text =
        '123 Main St, City, Country'; // Replace with actual address
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit User Information'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save the updated information
            // You can add your logic to save the updated information here
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class EditSubscriptionDialog extends StatefulWidget {
  final String selectedPlan;
  final ValueChanged<String> onPlanChanged;

  const EditSubscriptionDialog(
      {super.key, required this.selectedPlan, required this.onPlanChanged});

  @override
  _EditSubscriptionDialogState createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  late String _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.selectedPlan;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Subscription Plan'),
      content: DropdownButton<String>(
        value: _selectedPlan,
        onChanged: (String? newValue) {
          setState(() {
            _selectedPlan = newValue!;
          });
        },
        items: <String>['Basic', 'Bronze', 'Platinum']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onPlanChanged(_selectedPlan);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
