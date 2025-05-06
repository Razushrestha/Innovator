import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/course_riverpod.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final baseUrl = 'http://182.93.94.210:3064'; //Base Url for image & pdf

    return course.when(
        data: (courses) {
          if (courses == null || courses.isEmpty) {
            return Center(child: Text('No courses found'));
          }

          final selectedCourse = courses.first;
          final notesList = selectedCourse.notes;

          return Scaffold(
            body: ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                final note = notesList[index];
                return SizedBox(
                  height: 500,
                  child: SfPdfViewer.network(
                    '$baseUrl${note.pdf}',
                  ),
                );
              },
            ),
          );
        },
        error: (error, stackTrace) => Center(
              child: Text('Error to fetch data'),
            ),
        loading: () => Center(
              child: CircularProgressIndicator(),
            ));
  }
}
