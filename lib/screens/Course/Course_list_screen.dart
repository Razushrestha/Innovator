import 'package:flutter/material.dart';
import 'package:innovator/screens/Course/course_details_screen.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'dart:developer' as developer;

class CourseListScreen extends StatefulWidget {
  final ParentCategory parentCategory;
  final Subcategory subcategory;

  const CourseListScreen({
    Key? key,
    required this.parentCategory,
    required this.subcategory,
  }) : super(key: key);

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Course> _courses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _sortBy = 'newest';
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchCourses();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.getSubcategoryCourses(widget.subcategory.id);

      if (response['status'] == 200 && response['data'] != null) {
        final coursesJson = response['data']['courses'] as List;
        final courses = coursesJson.map((json) => Course.fromJson(json)).toList();

        setState(() {
          _courses = courses;
          _isLoading = false;
        });

        developer.log('Loaded ${courses.length} courses');
      } else {
        throw Exception(response['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToCourseDetail(Course course) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CourseDetailScreen(course: course),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('newest', 'Newest first', Icons.schedule),
            _buildSortOption('rating', 'Highest rated', Icons.star),
            _buildSortOption('price_low', 'Price: Low to High', Icons.arrow_upward),
            _buildSortOption('price_high', 'Price: High to Low', Icons.arrow_downward),
            _buildSortOption('popular', 'Most popular', Icons.trending_up),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromRGBO(244, 135, 6, 1)),
      title: Text(title),
      trailing: _sortBy == value
          ? const Icon(Icons.check, color: Color.fromRGBO(244, 135, 6, 1))
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
        _applySorting();
      },
    );
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          _courses.sort((a, b) => b.rating.average.compareTo(a.rating.average));
          break;
        case 'price_low':
          _courses.sort((a, b) => a.price.usd.compareTo(b.price.usd));
          break;
        case 'price_high':
          _courses.sort((a, b) => b.price.usd.compareTo(a.price.usd));
          break;
        case 'popular':
          _courses.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
          break;
        case 'newest':
        default:
          _courses.sort((a, b) => b.id.compareTo(a.id));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _hasError
                        ? _buildErrorWidget()
                        : _buildCoursesContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _parseColor(widget.subcategory.color),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort, color: Colors.white),
          onPressed: _showSortDialog,
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Implement search functionality
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '${widget.subcategory.name} Courses',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _parseColor(widget.subcategory.color),
                _parseColor(widget.subcategory.color).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 60,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(widget.subcategory.icon),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.subcategory.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(235, 111, 70, 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromRGBO(244, 135, 6, 1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading courses...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesContent() {
    if (_courses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_courses.length} courses found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(235, 111, 70, 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sort,
                      size: 16,
                      color: Color.fromRGBO(244, 135, 6, 1),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getSortDisplayName(),
                      style: const TextStyle(
                        color: Color.fromRGBO(244, 135, 6, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              return _buildCourseCard(_courses[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No courses available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Check back later for new courses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToCourseDetail(course),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course thumbnail
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _parseColor(widget.subcategory.color),
                              _parseColor(widget.subcategory.color).withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (course.thumbnail.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      ApiService.getFullMediaUrl(course.thumbnail),
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {},
                                  ),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  course.level.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (course.overviewVideo != null && course.overviewVideo!.isNotEmpty)
                              const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Course info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By ${course.instructor.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Rating
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      course.rating.average.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      ' (${course.rating.count})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Price
                                // Text(
                                //   '\${course.price.usd.toStringAsFixed(2)}',
                                //   style: const TextStyle(
                                //     fontSize: 18,
                                //     fontWeight: FontWeight.bold,
                                //     color: Color.fromRGBO(244, 135, 6, 1),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildCourseStatChip(
                                  '${course.contentStructure.totalLessons} lessons',
                                  Icons.play_lesson,
                                ),
                                const SizedBox(width: 8),
                                _buildCourseStatChip(
                                  '${course.contentStructure.totalVideos} videos',
                                  Icons.videocam,
                                ),
                                const SizedBox(width: 8),
                                _buildCourseStatChip(
                                  course.language,
                                  Icons.language,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(Course course) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          course.rating.average.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '(${course.rating.count})',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Course course) {
    return Text(
      '\${course.price.usd.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color.fromRGBO(244, 135, 6, 1),
      ),
    );
  }

  Widget _buildCourseStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayName() {
    switch (_sortBy) {
      case 'rating':
        return 'Rating';
      case 'price_low':
        return 'Price ↑';
      case 'price_high':
        return 'Price ↓';
      case 'popular':
        return 'Popular';
      case 'newest':
      default:
        return 'Newest';
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color.fromRGBO(244, 135, 6, 1);
    } catch (e) {
      return const Color.fromRGBO(244, 135, 6, 1);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'js':
        return Icons.javascript;
      case 'design':
        return Icons.design_services;
      case 'data':
        return Icons.analytics;
      case 'business':
        return Icons.business;
      case 'marketing':
        return Icons.campaign;
      case 'music':
        return Icons.music_note;
      case 'photo':
        return Icons.photo_camera;
      default:
        return Icons.category;
    }
  }
}