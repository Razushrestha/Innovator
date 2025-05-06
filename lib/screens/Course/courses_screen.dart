import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/course_riverpod.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final baseUrl = 'http://182.93.94.210:3064'; //Base Url for image & pdf
    // http://182.93.94.210:3064/courses/public/HELLO-1746427454250/thumbnail-1746427454338-836475.jpeg
    // http: //182.93.94.210:3064/courses/public/HELLO-1746427454250/syllabus-1746427454362-249473.pdf

    return Scaffold(
      appBar: AppBar(title: Text('Courses')),
      body: course.when(
        data: (courses) {
          if (courses == null || courses.isEmpty) {
            return Center(child: Text('No courses found'));
          }
          final course = courses.first;

          return ListView(
            children: [
              Card(
                child: Column(
                  children: [
                    Text(course.title),
                    Text(course.description),
                    Image.network('$baseUrl${course.thumbnail}'),

                    //this is a pdf showing used a package: syncfusion_flutter_pdfviewer
                    // SizedBox(
                    //   height: 500,
                    //   width: double.infinity,
                    //   child: SfPdfViewer.network(
                    //     '$baseUrl${course.syllabus}',
                    //   ),
                    // ),
                    Text(course.likes.toString()),
                    Text(course.comments.toString()),
                    Text(course.author.email)
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
