import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/course.dart';

const String studentName = 'Kadek Rica Cahyani';

const String studentNim = '2415051026';
const String apiUrl = 'https://course-api-pearl.vercel.app/courses';

const List<Map<String, String>> courses = [
  {
    'title': 'Flutter Dasar',
    'code': 'FL001',
    'description': 'Pengenalan Flutter dan Dart.',
    'category': 'Pemrograman',
  },
  {
    'title': 'UI Fundamentals',
    'code': 'UI002',
    'description': 'Dasar desain antarmuka pengguna.',
    'category': 'Desain',
  },
  {
    'title': 'Responsive Layout',
    'code': 'RL003',
    'description': 'Membuat tampilan untuk berbagai ukuran layar.',
    'category': 'Flutter',
  },
  {
    'title': 'Navigasi Flutter',
    'code': 'NV004',
    'description': 'Mengelola perpindahan halaman.',
    'category': 'Flutter',
  },
  {
    'title': 'State Management',
    'code': 'SM005',
    'description': 'Mengelola perubahan state aplikasi.',
    'category': 'Pemrograman',
  },
  {
    'title': 'Form dan Validasi',
    'code': 'FV006',
    'description': 'Membuat form dengan validasi input.',
    'category': 'Flutter',
  },
];

Future<List<Course>> fetchCourses() async {
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Course.fromJson(json)).toList();
  }

  throw Exception('HTTP ${response.statusCode}');
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    fetchCourses().then((data) {
      debugPrint('Jumlah course dari API: ${data.length}');
    }).catchError((error) {
      debugPrint('Gagal mengambil data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI Fundamentals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ResponsiveShell(),
    );
  }
}

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    CoursesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool expanded = constraints.maxWidth >= 840;

        if (expanded) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: Text('Courses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Courses',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentHeader extends StatelessWidget {
  const StudentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              child: Icon(Icons.school),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('NIM: $studentNim'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final String layoutName = width < 600
              ? 'Compact'
              : width < 840
                  ? 'Medium'
                  : 'Expanded';

          final int columnCount = width < 600
              ? 1
              : width < 840
                  ? 2
                  : 3;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const StudentHeader(),
              const SizedBox(height: 12),
              Text(
                'Selamat datang di aplikasi Flutter UI Fundamentals.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Ukuran layar: ${screenSize.width.toInt()} × '
                  '${screenSize.height.toInt()}'),
              Text('Orientasi: '
                  '${screenSize.width > screenSize.height ? "Landscape" : "Portrait"}'),
              Text('Breakpoint layout: $layoutName'),
              const SizedBox(height: 16),
              Text(
                'Ringkasan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: columnCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width < 600 ? 2.6 : 1.8,
                children: const [
                  SummaryCard(
                    title: 'Total Course',
                    value: '6',
                    icon: Icons.menu_book,
                  ),
                  SummaryCard(
                    title: 'Status',
                    value: 'Aktif',
                    icon: Icons.check_circle_outline,
                  ),
                  SummaryCard(
                    title: 'Platform',
                    value: 'Flutter',
                    icon: Icons.phone_android,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Materi yang dipelajari',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('MediaQuery')),
                  Chip(label: Text('LayoutBuilder')),
                  Chip(label: Text('Expanded')),
                  Chip(label: Text('Navigation')),
                  Chip(label: Text('Form Validation')),
                  Chip(label: Text('Debugging')),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Kasus A: teks panjang dibatasi dengan Expanded '
                'agar tidak menyebabkan Row overflow.',
              ),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$studentNim - $studentName - '
                      'teks sangat panjang yang akan membungkus '
                      'ke baris berikutnya tanpa melewati batas layar.',
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final Set<String> favoriteCodes = {};
  late Future<List<Course>> coursesFuture;

  @override
  void initState() {
    super.initState();
    coursesFuture = fetchCourses();
  }

  Future<void> refreshCourses() async {
    setState(() {
      coursesFuture = fetchCourses();
    });
    await coursesFuture;
  }

  Future<void> openCourse(Map<String, String> course) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailPage(course: course),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        favoriteCodes.add(course['code']!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Courses')),
      body: FutureBuilder<List<Course>>(
        future: coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal mengambil data: ${snapshot.error}'),
            );
          }

          final apiCourses = snapshot.data ?? [];

          if (apiCourses.isEmpty) {
            return const Center(
              child: Text('Tidak ada data course.'),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshCourses,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width < 600
                    ? 1
                    : (width < 840 ? 2 : 3);

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: apiCourses.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 210,
                  ),
                  itemBuilder: (context, index) {
                    final item = apiCourses[index];

                    final course = <String, String>{
                      'title': item.title,
                      'code': item.code,
                      'category': 'Course API',
                      'description': 'Mata kuliah dari API.',
                      'status': item.status,
                      'credits': item.credits.toString(),
                    };

                    return CourseCard(
                      course: course,
                      isFavorite: favoriteCodes.contains(item.code),
                      onFavorite: () {
                        setState(() {
                          if (!favoriteCodes.add(item.code)) {
                            favoriteCodes.remove(item.code);
                          }
                        });
                      },
                      onTap: () => openCourse(course),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}





class CourseCard extends StatelessWidget {
  final Map<String, String> course;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.menu_book, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] ?? '-',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text('Kode: ${course['code'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Status: ${course['status'] ?? 'planned'}'),
                    Text('SKS: ${course['credits'] ?? '-'}'),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Hapus favorit'
                            : 'Tambah favorit',
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class CourseDetailPage extends StatefulWidget {
  final Map<String, String> course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool isFavorite = false;
  bool isNavigating = false;

  void selectAndReturn() {
    if (isNavigating) return;

    setState(() {
      isNavigating = true;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Course')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StudentHeader(),
          const SizedBox(height: 16),
          Icon(
            Icons.menu_book,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            course['title']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          DetailInfo(label: 'Kode', value: course['code']!),
          DetailInfo(
            label: 'Kategori',
            value: course['category']!,
          ),
          DetailInfo(
            label: 'Deskripsi',
            value: course['description']!,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            label: Text(
              isFavorite ? 'Hapus Favorit' : 'Tambah Favorit',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: isNavigating ? null : selectAndReturn,
            child: Text(
              isNavigating ? 'Memproses...' : 'Pilih Course dan Kembali',
            ),
          ),
        ],
      ),
    );
  }
}

class DetailInfo extends StatelessWidget {
  final String label;
  final String value;

  const DetailInfo({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: studentName);
  final nimController = TextEditingController(text: studentNim);
  final feedbackController = TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    nimController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    final dialogContext = context;

    final bool? confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text(
            'Apakah kamu yakin ingin mengirim feedback?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );

  if (!mounted) return;
  if (confirmed != true || isSubmitting) return;

setState(() {
  isSubmitting = true;
});

if (!mounted) return;
if (confirmed != true || isSubmitting) return;

setState(() {
  isSubmitting = true;
});

    if (confirmed != true || !mounted || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback berhasil dikirim!'),
      ),
    );

    feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil dan Feedback')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StudentHeader(),
                        const SizedBox(height: 20),
                        Text(
                          'Form Feedback',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nimController,
                          decoration: const InputDecoration(
                            labelText: 'NIM',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'NIM wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: feedbackController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Feedback',
                            hintText: 'Tulis minimal 5 karakter',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().length < 5) {
                              return 'Feedback minimal 5 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: isSubmitting ? null : submitForm,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            isSubmitting ? 'Mengirim...' : 'Kirim Feedback',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Catatan: form dapat digulir saat keyboard terbuka.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}