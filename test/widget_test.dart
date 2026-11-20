import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ui_fundamentals/main.dart';
import 'package:flutter_ui_fundamentals/providers/course_provider.dart';
import 'package:flutter_ui_fundamentals/providers/profile_provider.dart';
import 'package:flutter_ui_fundamentals/models/course.dart';
import 'package:flutter_ui_fundamentals/services/course_data_source.dart';
import 'package:flutter_ui_fundamentals/repositories/course_repository.dart';

class MockCourseDataSource implements CourseDataSource {
  @override
  Future<List<Course>> getCourses() async => [];

  @override
  Future<Course> createCourse(Course course) async => course;

  @override
  Future<void> updateCourse(int id, Course course) async {}

  @override
  Future<void> deleteCourse(int id) async {}
}

void main() {
  testWidgets('Course Data Manager displays student name and NIM', (
    WidgetTester tester,
  ) async {
    final mockRepo = CourseRepository(MockCourseDataSource());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CourseProvider(mockRepo)),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(studentName), findsWidgets);
    expect(find.text('NIM: $studentNim'), findsWidgets);
  });
}
