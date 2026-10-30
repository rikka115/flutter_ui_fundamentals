
import '../models/course.dart';
import '../services/course_api_service.dart';

class CourseRepository {
  CourseRepository(this.apiService);

  final CourseApiService apiService;

  Future<List<Course>> loadCourses() {
    return apiService.getCourses();
  }
}

