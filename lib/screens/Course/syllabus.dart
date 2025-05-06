import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/screens/Course/course_riverpod.dart';
import 'package:innovator/screens/Course/notes.dart';


class Syllabus extends ConsumerWidget {
  const Syllabus({super.key});

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

          return ListView.builder(
            itemCount: notesList.length,
            itemBuilder: (context, index) {
              final courseItem = notesList[index];
              // return Column(
              //   children: [
              //     SizedBox(
              //       height: 500,
              //       width: double.infinity,
              //       child: SfPdfViewer.network(
              //         '$baseUrl${courseItem.syllabus}',
              //       ),
              //     ),
              //   ],
              // );
              return Card(
                color: Colors.white,
                elevation: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(courseItem.name),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderScope(child:  NotesScreen()),
                              ));
                        },
                        icon: Icon(Icons.arrow_forward_ios_sharp))
                  ],
                ),
              );
            },
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
