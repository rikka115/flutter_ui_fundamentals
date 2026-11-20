import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_keys.dart';
import 'config/supabase_config.dart';
import 'pages/login_page.dart';
import 'providers/profile_provider.dart';
import 'providers/course_provider.dart';
import 'repositories/course_repository.dart';
import 'screens/responsive_shell.dart';
// ignore: unused_import
import 'services/course_api_service.dart';
import 'services/course_data_source.dart';
import 'services/course_supabase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

const String studentName = 'Kadek Rica Cahyani';
const String studentNim = '2415051026';
const String baseUrl = 'https://course-api-pearl.vercel.app';
const String supabaseUrl = SupabaseConfig.url;
const String supabaseAnonKey = SupabaseConfig.anonKey;

// =============================================================================
// KONFIGURASI DATA SOURCE AKTIF (Tahap 16)
// Sesuai arsitektur Repository Pattern, hanya satu baris ini yang diubah
// untuk berpindah sumber data antara REST API dan Supabase Database:
// =============================================================================
final CourseDataSource dataSource = CourseSupabaseService();
// final CourseDataSource dataSource = CourseApiService(baseUrl);

final repository = CourseRepository(dataSource);
String? supabaseInitializationError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase belum dikonfigurasi: $e');
  }

  // Inisialisasi Supabase Client jika URL sudah diisi
  try {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    }
  } catch (e) {
    supabaseInitializationError = e.toString();
    debugPrint('Supabase init warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CourseProvider(repository)..loadCourses(),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Data Manager',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const ResponsiveShell(
        homePage: HomePage(),
        profilePage: ProfilePage(),
      );
    }

    if (supabaseInitializationError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase gagal diinisialisasi: $supabaseInitializationError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        if (session == null) return const LoginPage();
        return _AuthenticatedProject(key: ValueKey(session.user.id));
      },
    );
  }
}

class _AuthenticatedProject extends StatefulWidget {
  const _AuthenticatedProject({super.key});

  @override
  State<_AuthenticatedProject> createState() => _AuthenticatedProjectState();
}

class _AuthenticatedProjectState extends State<_AuthenticatedProject> {
  @override
  void initState() {
    super.initState();
    final courseProvider = context.read<CourseProvider>();
    final profileProvider = context.read<ProfileProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await courseProvider.loadCourses();
      await profileProvider.load();
      try {
        await NotificationService.instance.init();
        await NotificationService.instance.setupInteractedMessage();
      } catch (e) {
        debugPrint('Gagal mengaktifkan notifikasi: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveShell(
      homePage: HomePage(),
      profilePage: ProfilePage(),
    );
  }
}

// =============================================================================
// WIDGET PENDUKUNG (Dashboard, Profile, StudentHeader dari Pertemuan sebelumnya)
// =============================================================================

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
            const CircleAvatar(child: Icon(Icons.school)),
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
                  const Text('NIM: $studentNim'),
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
    final provider = context.watch<CourseProvider>();

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
                'Selamat datang di Course Data Manager.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ukuran layar: ${screenSize.width.toInt()} × ${screenSize.height.toInt()}',
              ),
              Text(
                'Orientasi: ${screenSize.width > screenSize.height ? "Landscape" : "Portrait"}',
              ),
              Text('Breakpoint layout: $layoutName'),
              const SizedBox(height: 16),
              Text('Ringkasan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: columnCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width < 600 ? 2.6 : 1.8,
                children: [
                  SummaryCard(
                    title: 'Total Course',
                    value: provider.courses.length.toString(),
                    icon: Icons.menu_book,
                  ),
                  SummaryCard(
                    title: 'Favorit',
                    value: provider.favoriteCourses.length.toString(),
                    icon: Icons.favorite,
                  ),
                  const SummaryCard(
                    title: 'Platform',
                    value: 'Flutter & Backend',
                    icon: Icons.cloud_done,
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
                  Chip(label: Text('REST API')),
                  Chip(label: Text('HTTP GET/POST/PUT/DELETE')),
                  Chip(label: Text('Supabase Backend')),
                  Chip(label: Text('PostgreSQL Database')),
                  Chip(label: Text('Repository Pattern')),
                  Chip(label: Text('Responsive Navigation')),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$studentNim - $studentName - Course Data Manager berhasil terintegrasi dengan REST API dan Supabase PostgreSQL.',
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
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah kamu yakin ingin mengirim feedback?'),
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

    if (confirmed != true || !mounted || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback berhasil dikirim!')));

    feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil dan Feedback'),
        actions: [
          if (SupabaseConfig.isConfigured)
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: AuthService.instance.logout,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StudentHeader(),
                    if (SupabaseConfig.isConfigured) ...[
                      const SizedBox(height: 12),
                      if (profileState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (profileState.profile != null)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.account_circle_outlined),
                            title: Text(
                              profileState.profile!.name.isEmpty
                                  ? profileState.profile!.email
                                  : profileState.profile!.name,
                            ),
                            subtitle: Text(
                              '${profileState.profile!.email} • Role: ${profileState.profile!.role}',
                            ),
                          ),
                        )
                      else if (profileState.error != null)
                        Text('Profil gagal dimuat: ${profileState.error}'),
                    ],
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
                        if (value == null || value.trim().length < 5) {
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
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        isSubmitting ? 'Mengirim...' : 'Kirim Feedback',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
