import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import 'course_data_source.dart';

class CourseApiService implements CourseDataSource {
  CourseApiService(this.baseUrl);

  final String baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 10);

  @override
  Future<List<Course>> getCourses() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/courses'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        throw const HttpException('Resource tidak ditemukan (404)');
      } else {
        throw HttpException('Server error: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw TimeoutException('Koneksi timeout. Server tidak merespons dalam waktu yang ditentukan.');
    }
  }

  @override
  Future<Course> createCourse(Course course) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/courses'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(course.toJson()),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Course.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 400) {
        throw const HttpException('Data tidak valid (400)');
      } else {
        throw HttpException('Gagal membuat course: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw TimeoutException('Koneksi timeout.');
    }
  }

  @override
  Future<void> updateCourse(int id, Course course) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/courses/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(course.toJson()),
          )
          .timeout(timeoutDuration);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Gagal memperbarui course: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw TimeoutException('Koneksi timeout.');
    }
  }

  @override
  Future<void> deleteCourse(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/courses/$id'))
          .timeout(timeoutDuration);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Gagal menghapus course: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw TimeoutException('Koneksi timeout.');
    }
  }
}
