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
        title: const Text('Course Data Manager'),
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
        padding: const EdgeInsets.all(12),
        children: [
          // Student identity banner
          Card(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '2415051026 • Kadek Rica Cahyani',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Add Course Button Banner (sesuai mockup Tahap 16)
          if (canManageCourses)
            Card(
              color: Colors.green.withValues(alpha: 0.12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseFormPage(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Course',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          if (provider.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Data course belum tersedia',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
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
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 160,
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
