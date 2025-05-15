import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/Services/course_service.dart';
import 'package:innovator/screens/Course/model/courses_model.dart';


final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

final courseProvider = FutureProvider<List<Data>?>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  return await courseService.fetchCourses();
});

//for whole
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nepatronix/model/courses_model.dart';
// import 'package:nepatronix/services/course_service.dart';

// final courseServiceProvider = Provider<CourseService>((ref) {
//   return CourseService();
// });

// final courseProvider = FutureProvider<Courses>((ref) async {
//   final courseService = ref.read(courseServiceProvider);
//   final courses = await courseService.fetchCourses();
//   return courses;
// });
