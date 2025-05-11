import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/course_riverpod.dart';
import 'package:innovator/screens/Course/syllabus.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';


class UiUxCard extends ConsumerStatefulWidget {
  const UiUxCard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UiUxCardState();
}

class _UiUxCardState extends ConsumerState<UiUxCard>
    with SingleTickerProviderStateMixin {
        final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider);
    final baseUrl = 'http://182.93.94.210:3064'; //Base Url for image & pdf
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    //height
    final smallPhoneheight = screenHeight <= 640;
    final smallPhoneWidth = screenWidth < 360;
    return course.when(
      data: (courses) {
        if (courses == null || courses.isEmpty) {
          return Center(child: Text('No courses found'));
        }
        final course = courses.first;

        return Scaffold(
                key: _scaffoldKey, // Add the scaffold key here

          backgroundColor: const Color(0xffEDF4FE),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: const Color(0xffEDF4FE),
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: smallPhoneWidth ? 35 : 42,
                  height: smallPhoneheight ? 35 : 45,
                  decoration: BoxDecoration(
                    color: Color(0xffE1EAFF),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_outlined,
                        color: Color(0xff7081F5),
                      )),
                ),
                Text(
                  // 'UI/UX Design Class',
                  course.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Container(
                  width: smallPhoneWidth ? 35 : 42,
                  height: smallPhoneheight ? 35 : 45,
                  decoration: BoxDecoration(
                    color: Color(0xffE1EAFF),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.star_border_rounded,
                        color: Color(0xff7081F5),
                      )),
                ),
              ],
            ),
          ),
          body: Stack(children: [

            Padding(
              padding: EdgeInsets.only(right: 20, left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    // child: Image.asset(
                    //   'assets/uicoursevideo.png',
                    //   fit: BoxFit.contain,
                    // ),
                    child: Image.network('$baseUrl${course.thumbnail}'),
                  ),
                  SizedBox(
                    height: smallPhoneheight ? 5 : 15,
                  ),
                  Text(
                    course.title,
                    style: TextStyle(
                        fontSize: smallPhoneWidth ? 18 : 20,
                        letterSpacing: smallPhoneWidth ? 0.7 : 1.2,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: smallPhoneheight ? 3 : 5,
                  ),
                  Row(
                    children: [
                      Text(
                        'Mentor With',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: smallPhoneheight ? 11 : 13),
                      ),
                      SizedBox(
                        width: smallPhoneWidth ? 5 : 7,
                      ),
                      Text(
                        'Nepa Tronix',
                        style: TextStyle(
                          color: Color(0xff7081F5),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: smallPhoneWidth ? 4 : 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_border_outlined,
                            size: smallPhoneheight ? 15 : 18,
                            color: Colors.orange,
                          ),
                          SizedBox(
                            width: smallPhoneWidth ? 3 : 4,
                          ),
                          Text(
                            '4.8/5',
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.watch_later_outlined,
                            size: smallPhoneheight ? 15 : 18,
                            color: Colors.blue,
                          ),
                          SizedBox(
                            width: smallPhoneWidth ? 3 : 4,
                          ),
                          Text(
                            '12 h 34m',
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      Text(
                        //This shows the price in NPR and can be shown in USD in case needed
                        'Rs. ${course.price.npr.toString()}',
                        style: TextStyle(
                          fontSize: smallPhoneheight ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff7081F5),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: smallPhoneheight ? 12 : 25,
                  ),
                  Container(
                    // clipBehavior: Clip.antiAlias,
                    height: smallPhoneheight ? 30 : 50,
                    decoration: BoxDecoration(
                        color: Color(0xffFCFCFB),
                        borderRadius: BorderRadius.circular(20)),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      unselectedLabelColor: Color(0xff7081F5),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Color(0xff7081F5),
                      ),
                      tabs: const [
                        Tab(
                          text: 'Syllabus',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: smallPhoneheight ? 5 : 7,
                  ),
                  //Content of the tab from the another screen
                  Expanded(
                    child: TabBarView(
                        controller: _tabController, children: [ProviderScope(child: Syllabus(),)]),
                  ),
                  //ElevatedButton after the tab screen view
            
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                            Color(0xff7081F5),
                          )),
                          onPressed: () {},
                          child: Text(
                            'Enroll Now',
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                  )
                ],
              ),
            ),
            FloatingMenuWidget(scaffoldKey: _scaffoldKey,)
          ]
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
