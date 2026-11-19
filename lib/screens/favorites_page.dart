import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../widgets/course_card.dart';
import 'course_detail_page.dart';
import 'course_form_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final favorites = provider.favoriteCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Favorit'),
      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favorites.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 160,
                  ),
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return CourseCard(
                      course: item,
                      isFavorite: true,
                      onFavorite: () => provider.toggleFavorite(item.code),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailPage(course: item),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseFormPage(course: item),
                          ),
                        );
                      },
                      onDelete: () async {
                        if (item.id != null) {
                          await provider.deleteCourse(item.id!, item.code);
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
