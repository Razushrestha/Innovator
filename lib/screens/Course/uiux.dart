import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/course_riverpod.dart';
import 'package:innovator/screens/Course/ui_ux_card.dart';


class UIUXDesignScreen extends ConsumerWidget {
  const UIUXDesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Height categories
    final smallPhoneheight = screenHeight <= 640;
    final mediumPhoneheight = screenHeight > 640 && screenHeight <= 732;

    // Width categories
    final smallPhoneWidth = screenWidth < 360;

    final isMediumDevice = screenWidth >= 1400 &&
        screenWidth < 1800 &&
        screenHeight >= 700 &&
        screenHeight <= 800;
    final course = ref.watch(courseProvider);
    final baseUrl = 'http://182.93.94.210:3064'; //Base Url for image & pdf

    return course.when(
      data: (courses) {
        if (courses == null || courses.isEmpty) {
          return Center(child: Text('No courses found'));
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMediumDevice
                ? screenWidth * 0.02
                : (smallPhoneWidth ? screenWidth * 0.03 : screenWidth * 0.05),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final currentCourse = courses[index];
              return Padding(
                  padding: EdgeInsets.only(right: isMediumDevice ? 15 : 10),
                  child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProviderScope(child: UiUxCard())) );
                      },
                      child: buildCourseCard(
                        context,
                        smallPhoneWidth,
                        smallPhoneheight,
                        isMediumDevice,
                        // 'UI/UX Design',
                        currentCourse.title,
                        // 'We will learn from the beginning to become a product',
                        // course.description,
                        currentCourse.description,
                        // 'assets/cardphoto1.png',
                        '$baseUrl${currentCourse.thumbnail}',
                        Color(0xff0EB869),
                        Color(0xff27C179),
                        currentCourse.notes.length.toString(),
                        '12h 34m',
                      )));
            },
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget buildCourseCard(
    BuildContext context,
    bool smallPhoneWidth,
    bool smallPhoneheight,
    bool isMediumDevice,
    String title,
    String description,
    String imagePath,
    Color cardColor,
    Color backgroundColor,
    String filesCount,
    String duration,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Calculate appropriate width based on device size
    double cardWidth;
    if (isMediumDevice) {
      // For 1600×720 devices, make cards much narrower
      cardWidth = screenWidth * 0.25;
    } else if (smallPhoneWidth) {
      cardWidth = screenWidth * 0.9;
    } else {
      cardWidth = screenWidth * 0.53;
    }

    // Fixed aspect ratio to ensure proportional cards
    final double aspectRatio = isMediumDevice ? 0.5 : 0.5;
    // Only set cardHeight for medium devices, otherwise it will be null (auto height)
    final double? cardHeight = isMediumDevice ? cardWidth / aspectRatio : null;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      child: Stack(
        children: [
          // Background circle
          Positioned(
            top: smallPhoneheight ? -20 : (isMediumDevice ? -25 : -38),
            right: smallPhoneheight ? 0 : (isMediumDevice ? -5 : -10),
            child: Container(
              width: smallPhoneheight ? 100 : (isMediumDevice ? 120 : 200),
              height: smallPhoneheight ? 10 : (isMediumDevice ? 80 : 170),
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMediumDevice ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: smallPhoneheight ? 5 : (isMediumDevice ? 6 : 7),
                  child: Center(
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Spacing between image and text
                SizedBox(
                  height: smallPhoneheight ? 8 : (isMediumDevice ? 10 : 15),
                ),

                // Text content at the bottom
                Expanded(
                  flex: smallPhoneheight ? 6 : (isMediumDevice ? 7 : 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: smallPhoneheight
                              ? 12
                              : (isMediumDevice ? 15 : 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      // Small spacing
                      SizedBox(
                        height: isMediumDevice ? 6 : (smallPhoneheight ? 6 : 8),
                      ),

                      // Description
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Spacer(),

                      // Bottom stats section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            height: isMediumDevice ? 25 : 30,
                            width: isMediumDevice ? 25 : 30,
                            child: Icon(
                              Icons.description,
                              color: Colors.orange,
                              size: isMediumDevice ? 16 : 20,
                            ),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '$filesCount Files',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMediumDevice
                                  ? 11
                                  : (smallPhoneWidth ? 10 : 12),
                            ),
                          ),
                          SizedBox(
                            width: isMediumDevice
                                ? 8
                                : (smallPhoneWidth ? 10 : 20),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            height: isMediumDevice ? 25 : 30,
                            width: isMediumDevice ? 25 : 30,
                            child: Icon(
                              Icons.watch_later_sharp,
                              color: Colors.blue,
                              size: isMediumDevice ? 16 : 20,
                            ),
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              duration,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMediumDevice
                                    ? 11
                                    : (smallPhoneWidth ? 10 : 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20), // Small bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
