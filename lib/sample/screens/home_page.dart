
import 'package:flutter/material.dart';
import 'package:innovator/sample/screens/about_page.dart';
import 'package:innovator/sample/screens/community.dart';
import 'package:innovator/sample/screens/course/course.dart';
import 'package:innovator/sample/screens/course/dourse_details.dart';
import 'package:innovator/sample/screens/course_details.dart' as subscription;
import 'package:innovator/sample/screens/help_page.dart';
import 'package:innovator/sample/screens/notification_page.dart';
import 'package:innovator/sample/screens/profile_page.dart';
import 'package:innovator/sample/screens/settings_page.dart';
import 'package:innovator/sample/screens/shop_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';

class Course_HomePage extends StatefulWidget {
  const Course_HomePage({super.key});

  @override
  _Course_HomePageState createState() => _Course_HomePageState();
}

class _Course_HomePageState extends State<Course_HomePage> {
  final List<String> trendingImages = [
    'assets/images/trending1.jpg',
    'assets/images/trending2.jpg',
    'assets/images/trending3.jpg',
    'assets/images/trending4.jpg',
    'assets/images/featured1.jpg',
  ];

  final List<Map<String, String>> featuredCourses = [
    {'image': 'assets/images/featured1.jpg', 'title': 'Course 1'},
    {'image': 'assets/images/featured2.jpg', 'title': 'Course 2'},
  ];

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final CarouselSliderController _materialsController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
     // drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrond.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTrendingCoursesBanner(),
                  SizedBox(height: 20),
                  _buildSectionTitle('Featured Courses'),
                  _buildFeaturedCoursesCarousel(),
                  SizedBox(height: 20),
                  _buildSectionTitle('Statistics'),
                  _buildStatisticsSection(),
                  SizedBox(height: 20),
                  _buildSectionTitle('Materials'),
                  _buildMaterialsSection(),
                ],
              ),
            ),
          ),
                    FloatingMenuWidget(),
    
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.7),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerTile(context, Icons.home, 'Home'),
          _buildDrawerTile(context, Icons.home, 'ShopPage', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShopPage()),
            );
          }),
          _buildDrawerTile(context, Icons.book, 'Courses', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoursePage()),
            );
          }),
          _buildDrawerTile(context, Icons.person, 'Profile', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfilePage()),
            );
          }),
          _buildDrawerTile(context, Icons.notifications, 'Notifications',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          }),
          _buildDrawerTile(context, Icons.help, 'Help', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelpPage()),
            );
          }),
          _buildDrawerTile(context, Icons.info, 'About', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutPage()),
            );
          }),
          _buildDrawerTile(context, Icons.subscriptions, 'Subscription',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => subscription.SubscriptionPage()),
            );
          }),
          _buildDrawerTile(context, Icons.group, 'Community', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityPage()),
            );
          }),
          _buildDrawerTile(context, Icons.group, 'Settings', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          }),
         
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(title),
      ),
      onTap: onTap ??
          () {
            if (title == 'Community') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityPage()),
              );
            } else {
              Navigator.pop(context);
            }
          },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildTrendingCoursesBanner() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 300,
          autoPlay: false,
          enlargeCenterPage: true,
          enableInfiniteScroll: true,
          viewportFraction: 1.0,
          aspectRatio: 16 / 9,
        ),
        items: trendingImages.map((imagePath) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Text(
                          'Trending Course',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black.withOpacity(0.7),
                                offset: Offset(3.0, 3.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedCoursesCarousel() {
    return Stack(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 200,
            autoPlay: false,
            enlargeCenterPage: true,
            viewportFraction: 0.5,
          ),
          items: featuredCourses.map((course) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetails(),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: Image.asset(
                                course['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              course['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        // Left arrow
        Positioned(
          left: 10,
          top: 90,
          child: IconButton(
            icon: Icon(Icons.arrow_left, size: 30, color: Colors.deepPurple),
            onPressed: () {
              _carouselController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ),
        // Right arrow
        Positioned(
          right: 10,
          top: 90,
          child: IconButton(
            icon: Icon(Icons.arrow_right, size: 30, color: Colors.deepPurple),
            onPressed: () {
              _carouselController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatisticCard(
            icon: Icons.people,
            title: 'Students',
            value: '1500+',
            color: Colors.blue,
            gradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.6), Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(width: 10),
          _buildStatisticCard(
            icon: Icons.school,
            title: 'Colleges',
            value: '50+',
            color: Colors.green,
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.6), Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(width: 10),
          _buildStatisticCard(
            icon: Icons.local_library,
            title: 'Courses',
            value: '200+',
            color: Colors.orange,
            gradient: LinearGradient(
              colors: [Colors.orange.withOpacity(0.6), Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMaterialCard(
                icon: Icons.book,
                title: 'Books',
                value: 'View All',
                color: Colors.red,
                gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.6), Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  // Navigate to books list
                },
              ),
              SizedBox(width: 10),
              _buildMaterialCard(
                icon: Icons.note,
                title: 'Notes',
                value: 'View All',
                color: Colors.purple,
                gradient: LinearGradient(
                  colors: [Colors.purple.withOpacity(0.6), Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  // Navigate to notes list
                },
              ),
              SizedBox(width: 10),
              _buildMaterialCard(
                icon: Icons.video_library,
                title: 'Videos',
                value: 'View All',
                color: Colors.teal,
                gradient: LinearGradient(
                  colors: [Colors.teal.withOpacity(0.6), Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  // Navigate to videos list
                },
              ),
              SizedBox(width: 10),
              _buildMaterialCard(
                icon: Icons.build,
                title: 'Projects',
                value: 'View All',
                color: Colors.brown,
                gradient: LinearGradient(
                  colors: [Colors.brown.withOpacity(0.6), Colors.brown[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  // Navigate to projects list
                },
              ),
            ],
          ),
        ),
        // Left arrow
        Positioned(
          left: 10,
          top: 60,
          child: IconButton(
            icon: Icon(Icons.arrow_left, size: 30, color: Colors.deepPurple),
            onPressed: () {
              _materialsController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ),
        // Right arrow
        Positioned(
          right: 10,
          top: 60,
          child: IconButton(
            icon: Icon(Icons.arrow_right, size: 30, color: Colors.deepPurple),
            onPressed: () {
              _materialsController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 150,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
