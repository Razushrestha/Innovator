import 'dart:math';

import 'package:flutter/material.dart';
import 'package:innovator/constant/app_colors.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> with SingleTickerProviderStateMixin{
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Separate state variables for each section
  bool isWhatInfoHighlightVisible = false;
  bool isHowUseHighlightVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            key: _scaffoldKey, // Add the scaffold key here

      // backgroundColor: const Color(0xffEDF4FE),
      // backgroundColor: AppColors.background,
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   centerTitle: true,
      //   title: Text(
      //     'Privacy Policy',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      // ),
      body: Stack(
        children: [
         Padding(
          padding: const EdgeInsets.only(top: 65, right: 20, left: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'What is the Privacy Policy and what does it cover?',
                  softWrap: true,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      wordSpacing: 2,
                      letterSpacing: 1.5),
                ),
                SizedBox(
                  height: 8,
                ),
                Text('Effective From May 9 2025'),
                SizedBox(
                  height: 10,
                ),
                Text(
                  '''We at Innovator want you to understand what information we collect, and how we use and share it. That's why we encourage you to read our Privacy Policy. This helps you use  in the way that's right for you. 
        In the Privacy Policy, we explain how we collect, use, share, retain and transfer information. We also let you know your rights. Each section of this Policy includes helpful examples and simpler language to make our practices easier to understand. We've also added links to resources where you can learn more about the privacy topics that interest you. 
        It's important to us that you know how to control your privacy, so we also show you where you can manage your information in the settings of the Innovator Products you use. You can  to shape your experience.\n 
        Read the full Policy below''',
                  style: TextStyle(
                    fontSize: 16,
                    wordSpacing: sqrt(3.5),
                    leadingDistribution: TextLeadingDistribution.proportional,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'What information do we collect?',
                  softWrap: true,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      wordSpacing: 2,
                      letterSpacing: 1.5),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      // color: Colors.white
                      color: AppColors.background),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isWhatInfoHighlightVisible = !isWhatInfoHighlightVisible;
                      });
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.pages),
                          SizedBox(width: 8),
                          Text('Highlights'),
                          Spacer(),
                          Icon(isWhatInfoHighlightVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isWhatInfoHighlightVisible)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        // color: Colors.grey.shade50,
                        color: AppColors.background),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In this Policy we list the kinds of information we collect. Here are some important ones. We collect:',
                        ),
                        SizedBox(height: 12),
                        _buildBulletPoint(
                            'The information you give us when you sign up for our Products and create a profile, like your email address, phone number or age'),
                        _buildBulletPoint(
                          'What you do on our Products. This includes what you click on or like, your posts and photos and messages you send. On some Products, you can use end-to-end encrypted messages.',
                        ),
                        _buildBulletPoint(
                            'Who your friends or followers are, and what they do on our Products'),
                        _buildBulletPoint(
                            'Information from the phone, computer, or tablet you use our Products on, like what kind it is and what version of our app you\'re using'),
                        _buildBulletPoint(
                          'Information from partners about things you do both on and off of our Products. This could include other websites you visit, apps you use or online games you play.',
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'How do we use your information?',
                  softWrap: true,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      wordSpacing: 2,
                      letterSpacing: 1.5),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      // color: Colors.white
                      color: AppColors.background),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isHowUseHighlightVisible = !isHowUseHighlightVisible;
                      });
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.pages),
                          SizedBox(width: 8),
                          Text('Highlights'),
                          Spacer(),
                          Icon(isHowUseHighlightVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isHowUseHighlightVisible)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        // color: Colors.grey.shade50,
                        color: AppColors.background),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Here are some of the ways we use your information:',
                        ),
                        SizedBox(height: 12),
                        _buildBulletPoint(
                            'We personalize your experience, like by suggesting reels to watch or communities to join'),
                        _buildBulletPoint(
                          'We improve our Products by applying information about what you use them to do, and what else is happening on your device when our app crashes',
                        ),
                        _buildBulletPoint(
                            'We work to prevent harmful behavior and keep people safe on our Products'),
                        _buildBulletPoint(
                            'We send you messages about the Products you use or ones you might like, if you let us'),
                        _buildBulletPoint(
                          'We research for the good of people around the world, like to advance technology or to help out in a crisis',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15,)
              ],
            ),
          ),
        ),
        FloatingMenuWidget(scaffoldKey: _scaffoldKey)
        ]
      ),
    );
  }

  Widget _buildBulletPoint(
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: text, style: TextStyle(letterSpacing: 1.5))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
