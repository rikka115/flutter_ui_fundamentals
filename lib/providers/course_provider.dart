import 'package:flutter/material.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  CourseProvider(this.repository);

  final CourseRepository repository;

  List<Course> courses = [];
  bool isLoading = false;
  String? error;

  // Set kode course yang difavoritkan
  final Set<String> _favoriteCodes = {};

  Set<String> get favoriteCodes => Set.unmodifiable(_favoriteCodes);

  List<Course> get favoriteCourses =>
      courses.where((c) => _favoriteCodes.contains(c.code)).toList();

  bool isFavorite(String code) => _favoriteCodes.contains(code);

  void toggleFavorite(String code) {
    if (!_favoriteCodes.add(code)) {
      _favoriteCodes.remove(code);
    }
    notifyListeners();
  }

  Future<void> loadCourses() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      courses = await repository.getCourses();
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

  Future<void> deleteCourse(int id, [String? code]) async {
    await repository.deleteCourse(id);
    if (code != null) {
      _favoriteCodes.remove(code);
    }
    await loadCourses();
  }
}
