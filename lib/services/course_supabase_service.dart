import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import 'course_data_source.dart';

class CourseSupabaseService implements CourseDataSource {
  SupabaseClient get supabase => Supabase.instance.client;

  @override
  Future<List<Course>> getCourses() async {
    try {
      final data = await supabase
          .from('courses')
          .select()
          .order('id');
      return (data as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Akses ditolak oleh RLS Policy Supabase (403)');
      }
      throw Exception('Database error: ${e.message}');
    } on SocketException {
      throw const SocketException('Tidak dapat terhubung ke server Supabase.');
    } catch (e) {
      throw Exception('Gagal memuat data dari Supabase: $e');
    }
  }

  @override
  Future<Course> createCourse(Course course) async {
    try {
      final row = await supabase
          .from('courses')
          .insert(course.toJson())
          .select()
          .single();
      return Course.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Data duplikat: Kode course sudah terdaftar');
      }
      if (e.code == '23514') {
        throw Exception('Constraint check error: Status harus planned, active, atau done');
      }
      throw Exception('Gagal menambah ke database: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menambah data: $e');
    }
  }

  @override
  Future<void> updateCourse(int id, Course course) async {
    try {
      await supabase
          .from('courses')
          .update(course.toJson())
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui database: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memperbarui data: $e');
    }
  }

  @override
  Future<void> deleteCourse(int id) async {
    try {
      await supabase
          .from('courses')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus dari database: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghapus data: $e');
    }
  }
}
