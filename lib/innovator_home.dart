import 'package:flutter/material.dart';
import 'package:innovator/chatroom/API/api.dart';
import 'package:innovator/custom_drawer.dart';
import 'package:innovator/main.dart';
import 'package:innovator/models/chat_user.dart';
import 'package:innovator/screens/Inner_Homepage.dart';

class Homepage extends StatefulWidget {
  final ChatUser user;
  const Homepage({super.key, required this.user});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
      
  late final AnimationController _controller;
  late final Animation<double> _navWidthAnim;
  late final Animation<double> _feedFadeAnim;
  late final Animation<double> _createScaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _navWidthAnim = Tween<double>(
      begin: 0,
      end: 90,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _feedFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );

    _createScaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Initialize mq for global use
    mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Innovator Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
            Inner_HomePage(user: APIs.me,),
          // Feed Section
          // Center(
          //   child: FadeTransition(
          //     opacity: _feedFadeAnim,
          //     child: Container(
          //       width: screenWidth * 0.85,
          //       padding: const EdgeInsets.all(32),
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         borderRadius: BorderRadius.circular(24),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black.withOpacity(0.08),
          //             blurRadius: 15,
          //             offset: const Offset(0, 8),
          //             spreadRadius: 2,
          //           ),
          //         ],
          //       ),
          //       // child: SingleChildScrollView(
          //       //   child: Column(
          //       //     children: [
                    
          //       //     ],
          //       //     // mainAxisSize: MainAxisSize.min,
          //       //     // children: [
          //       //     //   Container(
          //       //     //     padding: const EdgeInsets.all(16),
          //       //     //     decoration: BoxDecoration(
          //       //     //       color: Colors.orange.withOpacity(0.1),
          //       //     //       shape: BoxShape.circle,
          //       //     //     ),
          //       //     //     child: const Icon(
          //       //     //       Icons.lightbulb_outline,
          //       //     //       size: 48,
          //       //     //       color: Colors.orange,
          //       //     //     ),
          //       //     //   ),
          //       //     //   const SizedBox(height: 24),
          //       //     //   const Text(
          //       //     //     "Welcome, Innovator!",
          //       //     //     textAlign: TextAlign.center,
          //       //     //     style: TextStyle(
          //       //     //       fontSize: 28,
          //       //     //       fontWeight: FontWeight.w700,
          //       //     //       color: Color(0xFF333333),
          //       //     //     ),
          //       //     //   ),
          //       //     //   const SizedBox(height: 12),
          //       //     //   const Text(
          //       //     //     "Let's create something amazing today!",
          //       //     //     textAlign: TextAlign.center,
          //       //     //     style: TextStyle(
          //       //     //       fontSize: 16, 
          //       //     //       color: Color(0xFF666666),
          //       //     //       height: 1.5,
          //       //     //     ),
          //       //     //   ),
          //       //     //   const SizedBox(height: 24),
          //       //     //   ElevatedButton(
          //       //     //     onPressed: () {},
          //       //     //     style: ElevatedButton.styleFrom(
          //       //     //       backgroundColor: Colors.blue.shade700,
          //       //     //       foregroundColor: Colors.white,
          //       //     //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //       //     //       shape: RoundedRectangleBorder(
          //       //     //         borderRadius: BorderRadius.circular(30),
          //       //     //       ),
          //       //     //       elevation: 2,
          //       //     //     ),
          //       //     //     child: const Text(
          //       //     //       "Get Started",
          //       //     //       style: TextStyle(
          //       //     //         fontSize: 16,
          //       //     //         fontWeight: FontWeight.w500,
          //       //     //       ),
          //       //     //     ),
          //       //     //   ),
          //       //     // ],
                    
          //       //   ),
          //       // ),
          //     ),
          //   ),
          // ),

          // Floating Nav Bar
          // AnimatedBuilder(
          //   animation: _navWidthAnim,
          //   builder: (context, child) {
          //     final topOffset = (screenHeight - 380) / 2;
          //     return Positioned(
          //       top: topOffset,
          //       right: 16,
          //       child: Material(
          //         elevation: 8,
          //         borderRadius: BorderRadius.circular(50),
          //         color: Colors.transparent,
          //         child: ClipRRect(
          //           borderRadius: BorderRadius.circular(50),
          //           child: Container(
          //             width: _navWidthAnim.value,
          //             color: const Color(0xFFD2B48C),
          //             padding: const EdgeInsets.symmetric(vertical: 24),
          //             child: _navWidthAnim.value > 20
          //                 ? Column(
          //                     mainAxisSize: MainAxisSize.min,
          //                     mainAxisAlignment: MainAxisAlignment.center,
          //                     children: [
          //                       _animatedButton(
          //                         icon: Icons.book,
          //                         onTap: () {},
          //                       ),
          //                       const SizedBox(height: 16),
          //                       _animatedButton(
          //                         icon: Icons.star,
          //                         onTap: () {},
          //                       ),
          //                       const SizedBox(height: 16),
          //                       ScaleTransition(
          //                         scale: _createScaleAnim,
          //                         child: Container(
          //                           width: 60,
          //                           height: 60,
          //                           decoration: BoxDecoration(
          //                             color: Colors.white,
          //                             shape: BoxShape.circle,
          //                             boxShadow: [
          //                               BoxShadow(
          //                                 color: Colors.orange.withOpacity(0.4),
          //                                 blurRadius: 8,
          //                                 offset: const Offset(0, 4),
          //                               ),
          //                             ],
          //                           ),
          //                           child: IconButton(
          //                             icon: const Icon(
          //                               Icons.add,
          //                               size: 32,
          //                               color: Colors.orange,
          //                             ),
          //                             tooltip: 'Create',
          //                             onPressed: () {},
          //                           ),
          //                         ),
          //                       ),
          //                       const SizedBox(height: 16),
          //                       _animatedButton(
          //                         icon: Icons.message,
          //                         onTap: () {},
          //                       ),
          //                       const SizedBox(height: 16),
          //                       _animatedButton(
          //                         icon: Icons.person,
          //                         onTap: () {},
          //                       ),
          //                     ],
          //                   )
          //                 : const SizedBox.shrink(),
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _animatedButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white24,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFA0522D),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}