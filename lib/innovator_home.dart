import 'package:flutter/material.dart';
import 'package:innovator/custom_drawer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innovator',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const InnovatorHomePage(),
    );
  }
}

class InnovatorHomePage extends StatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  _InnovatorHomePageState createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends State<InnovatorHomePage>
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

    return Scaffold(
      appBar: AppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Feed Section
          Center(
            child: FadeTransition(
              opacity: _feedFadeAnim,
              child: Container(
                width: screenWidth * 0.5,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(200),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(
                        245,
                        242,
                        242,
                        1,
                      ).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 48,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 18),
                    Text(
                      "Welcome, Innovator!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Let's create something amazing today!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Nav Bar
          AnimatedBuilder(
            animation: _navWidthAnim,
            builder: (context, child) {
              final topOffset = (screenHeight - 340) / 2;
              return Positioned(
                top: topOffset,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: _navWidthAnim.value,
                      color: const Color(0xFFD2B48C),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child:
                          _navWidthAnim.value > 30
                              ? Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _animatedButton(
                                    icon: Icons.book,
                                    onTap: () {},
                                  ),
                                  _animatedButton(
                                    icon: Icons.star,
                                    onTap: () {},
                                  ),
                                  ScaleTransition(
                                    scale: _createScaleAnim,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          size: 32,
                                          color: Colors.orange,
                                        ),
                                        tooltip: 'Create',
                                        onPressed: () {},
                                      ),
                                    ),
                                  ),
                                  _animatedButton(
                                    icon: Icons.message,
                                    onTap: () {},
                                  ),
                                  _animatedButton(
                                    icon: Icons.person,
                                    onTap: () {},
                                  ),
                                ],
                              )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          ),
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFA0522D),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
