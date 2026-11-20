import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/course_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/course_card.dart';
import 'course_detail_page.dart';
import 'course_form_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final canManageCourses = context.watch<ProfileProvider>().canManageCourses;
    final favorites = provider.favoriteCourses;

    return Scaffold(
      appBar: AppBar(title: const Text('Course Favorit')),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Course Favorit',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tandai ikon hati pada course untuk menambahkannya ke daftar favorit Anda.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width < 600 ? 1 : (width < 840 ? 2 : 3);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Koleksi Favorit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    '${favorites.length} course tersimpan',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: favorites.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 174,
                        ),
                        itemBuilder: (context, index) {
                          final item = favorites[index];
                          return CourseCard(
                            course: item,
                            isFavorite: true,
                            onFavorite: () =>
                                provider.toggleFavorite(item.code),
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
                                ? () async {
                                    if (item.id != null) {
                                      await provider.deleteCourse(
                                        item.id!,
                                        item.code,
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
