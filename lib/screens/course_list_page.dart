import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/course_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/course_card.dart';
import '../widgets/error_view.dart';
import '../widgets/role_guard.dart';
import 'course_detail_page.dart';
import 'course_form_page.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Course'),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoading ? null : provider.loadCourses,
          ),
        ],
      ),
      floatingActionButton: RoleGuard(
        role: profile.role,
        allowed: const ['admin'],
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CourseFormPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah Course'),
        ),
      ),
      body: _buildBody(context, provider, profile.canManageCourses),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CourseProvider provider,
    bool canManageCourses,
  ) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data course...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return ErrorView(message: provider.error!, onRetry: provider.loadCourses);
    }

    return RefreshIndicator(
      onRefresh: provider.loadCourses,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Course',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${provider.courses.length} materi tersedia',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (provider.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Data course belum tersedia',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width < 600 ? 1 : (width < 840 ? 2 : 3);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.courses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 174,
                  ),
                  itemBuilder: (context, index) {
                    final item = provider.courses[index];
                    return CourseCard(
                      course: item,
                      isFavorite: provider.isFavorite(item.code),
                      onFavorite: () => provider.toggleFavorite(item.code),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailPage(course: item),
                          ),
                        );
                      },
                      onEdit: canManageCourses
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseFormPage(course: item),
                                ),
                              );
                            }
                          : null,
                      onDelete: canManageCourses
                          ? () => _confirmDelete(context, provider, item)
                          : null,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CourseProvider provider,
    Course item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus course "${item.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      if (!context.mounted) return;
      try {
        await provider.deleteCourse(item.id!, item.code);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course berhasil dihapus')),
        );
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
  }
}
