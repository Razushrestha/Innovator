// import 'package:flutter/material.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           buildHeader(),
//           buildCourseSection(),
//         ],
//       ),
//     );
//   }

//   Widget buildHeader() {
//     return Container(
//       height: 210,
//       decoration: BoxDecoration(
//           color: Color(0xff5F73F3),
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(25),
//             bottomRight: Radius.circular(25),
//           )),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 20, top: 50),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Good Morning',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold)),
//                 Text(
//                   'Elizabeth Holzer',
//                   style: TextStyle(color: Colors.white70),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(bottom: 65, right: 20),
//             child: Stack(
//               children: [
//                 ClipOval(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white.withAlpha(20),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: IconButton(
//                       onPressed: () {},
//                       icon: Icon(Icons.notifications),
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   top: 14,
//                   right: 14,
//                   child: Container(
//                     height: 8,
//                     width: 8,
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget buildCourseSection() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('Course',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz))
//         ],
//       ),
//     );
//   }
// }
