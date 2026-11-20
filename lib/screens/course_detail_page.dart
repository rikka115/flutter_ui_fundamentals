import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/course_provider.dart';
import '../providers/profile_provider.dart';
import 'course_form_page.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final canManageCourses = context.watch<ProfileProvider>().canManageCourses;
    final isFavorite = provider.isFavorite(course.code);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Course'),
        actions: canManageCourses
            ? [
                IconButton(
                  tooltip: 'Hapus Course',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  onPressed: () async {
                    if (course.id == null) return;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Konfirmasi Hapus'),
                        content: Text(
                          'Apakah Anda yakin ingin menghapus course "${course.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!context.mounted) return;
                      try {
                        await context.read<CourseProvider>().deleteCourse(
                          course.id!,
                          course.code,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Course berhasil dihapus'),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menghapus course: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Edit Course',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseFormPage(course: course),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ]
            : [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1D4ED8),
                  child: Icon(Icons.school_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kadek Rica Cahyani',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'NIM: 2415051026  •  Pendidikan Teknik Informatika',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            course.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _DetailCard(label: 'Kode', value: course.code),
          _DetailCard(label: 'SKS / Credits', value: '${course.credits} SKS'),
          _DetailCard(label: 'Status', value: course.status.toUpperCase()),
          _DetailCard(label: 'Kategori', value: 'Course Data Manager'),
          _DetailCard(
            label: 'Deskripsi',
            value: 'Mata kuliah terdaftar pada database backend.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              provider.toggleFavorite(course.code);
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFDC2626) : null,
            ),
            label: Text(
              isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Pilih Course dan Kembali'),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;

  const _DetailCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
