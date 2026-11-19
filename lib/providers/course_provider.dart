import 'package:flutter/material.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  CourseProvider(this.repository);

  final CourseRepository repository;

  List<Course> courses = [];
  bool isLoading = false;
  String? error;

  Future<void> loadCourses() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      courses = await repository.loadCourses();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCourse(Course course) async {
    await repository.createCourse(course);
    await loadCourses();
  }

  Future<void> updateCourse(int id, Course course) async {
    await repository.updateCourse(id, course);
    await loadCourses();
  }

  Future<void> deleteCourse(int id) async {
    await repository.deleteCourse(id);
    await loadCourses();
  }
}
