import 'package:flutter/material.dart';
import 'package:innovator/constant/app_colors.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with SingleTickerProviderStateMixin{
      final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
                  key: _scaffoldKey, // Add the scaffold key here

      // backgroundColor: AppColors.appBackground,
      // backgroundColor: AppColors.background,
      body: Stack(
        children: [
        Padding(
          padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(
                  height: 15,
                ),
                dropDown(
                  'How do I reset my password?',
                  'Go to the Login page and click on "Reset Password". Follow the instructions sent to your email.',
                ),
                dropDown('How do I contact support?',
                    'You can contact support via the Help section or email us at support@nepatronix.org.'),
                dropDown('Where can I find my course materials?',
                    'All course materials are located under the "Courses" tab.'),
                dropDown('Why Nepatronix is not responding?',
                    'Please ensure you have a stable internet connection and try refreshing the app.'),
                dropDown('Why AI Math Tutor is not Giving Respose?',
                    'It may be due to system updates or technical issues. Please check back later.'),
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Contact Support',
                  style: TextStyle(color: Colors.black, fontSize: 23),
                ),
                SizedBox(
                  height: 8,
                ),
                name('Name'),
                SizedBox(
                  height: 8,
                ),
                // email('Email')
                name('Email'),
                SizedBox(
                  height: 8,
                ),
                name('Message'),
                SizedBox(
                  height: 10,
                ),
                Center(
                    child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(AppColors.background),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.black),
                        )))
              ],
            ),
          ),
        ),
                FloatingMenuWidget(scaffoldKey: _scaffoldKey)

        ]
      ),
    );
  }

  Widget dropDown(String question, String answer, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: const Color.fromRGBO(244, 135, 6, 1),
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          backgroundColor: Colors.orangeAccent,
          title: Text(
            question,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                answer,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget name(String text) {
    return Column(
      children: [
        TextFormField(
          maxLines: text == 'Message' ? 3 : 1,
          decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.background)),
              // disabledBorder: OutlineInputBorder(
              //     borderSide: BorderSide(color: AppColors.background)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.background)),
              hintText: text,
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.background))),
        ),
      ],
    );
  }
}
