import 'package:flutter/material.dart';
import 'package:innovator/screens/Course/digitalmarketing.dart';
import 'package:innovator/screens/Course/illustration_screen.dart';
import 'package:innovator/screens/Course/uiux.dart';
import 'package:innovator/screens/Course/web_development.dart';


class TabBarScreen extends StatefulWidget {
  const TabBarScreen({super.key});

  @override
  State<TabBarScreen> createState() => _TabBarScreenState();
}

class _TabBarScreenState extends State<TabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isSmallPhone = height <= 640;
    final isSmallWidth = width < 360;

    return SafeArea(
      //SafeArea widget to avoid notches and status bar
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xffEDF4FE),
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  _buildHeader(isSmallPhone, isSmallWidth),

                  // Course and tab section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: isSmallPhone ? height * 0.01 : height * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Course text
                        Text(
                          'Course',
                          style: TextStyle(
                            fontSize: isSmallPhone ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Options button
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.more_horiz),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // TabBar with aligned left padding to match "Course" text
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(
                      left: width * 0.04, // Same as "Course" text padding
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      unselectedLabelColor: Colors.black,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Color(0xff10B868),
                      ),
                      tabs: [
                        _buildTab(
                          Icons.design_services,
                          'UI/UX Design',
                          isSmallPhone,
                          null,
                        ),
                        _buildTab(
                          Icons.campaign_outlined,
                          'Digital Marketing',
                          isSmallPhone,
                          Colors.purpleAccent,
                        ),
                        _buildTab(
                          Icons.web,
                          'Web Development',
                          isSmallPhone,
                          Colors.lightBlue,
                        ),
                        _buildTab(
                          Icons.brush,
                          'Illustration',
                          isSmallPhone,
                          Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: isSmallPhone ? height * 0.02 : height * 0.03),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        UIUXDesignScreen(),
                        DigitalMarketingScreen(),
                        WebDevelopmentScreen(),
                        IllustrationScreen(),
                      ],
                    ),
                  ),
                ],
              ),

              // Search bar overlay
              Positioned(
                // top: isSmallPhone ? height * 0.14 : height * 0.16,
                top: isSmallPhone ? 90 : 140,
                left: width * 0.04,
                right: width * 0.04,
                child: _buildSearchBar(isSmallPhone, width),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header section with greeting and notification
  Widget _buildHeader(bool isSmallPhone, bool isSmallWidth) {
    return Container(
      height: isSmallPhone ? 150 : 200,
      decoration: BoxDecoration(
        color: Color(0xff5F73F3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting text
          Padding(
            padding: EdgeInsets.only(
              left: isSmallWidth ? 10 : 20,
              top: isSmallPhone ? 20 : 50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallPhone ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Elizabeth Holzer',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallPhone ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon
          Padding(
            padding: EdgeInsets.only(
              bottom: isSmallPhone ? 60 : 70,
              right: isSmallWidth ? 10 : 20,
            ),
            child: _buildNotificationButton(),
          ),
        ],
      ),
    );
  }

  // Notification button with badge
  Widget _buildNotificationButton() {
    return Stack(
      children: [
        ClipOval(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications),
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // Individual tab with icon and text
  Widget _buildTab(
      IconData icon, String text, bool isSmallPhone, Color? iconColor) {
    return Tab(
      height: isSmallPhone ? 32 : 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallPhone ? 16 : 18,
            color: iconColor,
          ),
          SizedBox(width: isSmallPhone ? 4 : 8),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallPhone ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  // Search bar widget
  Widget _buildSearchBar(bool isSmallPhone, double width) {
    return SearchBar(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      constraints: BoxConstraints(
        maxHeight: isSmallPhone ? 40 : 50,
      ),
      elevation: WidgetStateProperty.all(2),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      hintText: 'Search Course',
      hintStyle: WidgetStateProperty.all(
        TextStyle(
          color: Colors.grey,
          fontSize: isSmallPhone ? 14 : 16,
        ),
      ),
      leading: IconButton(
        onPressed: () {},
        icon: Icon(
          Icons.search,
          color: Colors.grey,
          size: isSmallPhone ? 20 : 24,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
