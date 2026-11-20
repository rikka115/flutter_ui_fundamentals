import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'services/profile_service.dart';
import 'services/rls_security_test.dart';

const String studentName = 'Kadek Rica Cahyani';
const String studentNim = '2415051026';
const Color _royalBlue = Color(0xFF1D4ED8);
const Color _skyBlue = Color(0xFF3B82F6);
const Color _pageBackground = Color(0xFFF3F6FC);
const String baseUrl = 'https://course-api-pearl.vercel.app';
const String supabaseUrl = SupabaseConfig.url;
const String supabaseAnonKey = SupabaseConfig.anonKey;

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

  // Inisialisasi Supabase Client jika URL & Anon Key sudah diisi
  try {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } else {
      supabaseInitializationError =
          'Konfigurasi Supabase belum diisi di lib/config/supabase_config.dart';
    }
  } catch (e) {
    supabaseInitializationError = e.toString();
    debugPrint('Supabase init warning: $e');
  }

  // ===========================================================================
  // KONFIGURASI DATA SOURCE AKTIF (Tahap 16)
  // Diinisialisasi setelah Supabase.initialize() selesai dijalankan
  // ===========================================================================
  final CourseDataSource dataSource = CourseSupabaseService();
  // final CourseDataSource dataSource = CourseApiService(baseUrl);
  final repository = CourseRepository(dataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider(repository)),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _royalBlue,
          primary: _royalBlue,
          secondary: _skyBlue,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: _pageBackground,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: _pageBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: Color(0xFF1E3A8A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: _royalBlue),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFDBEAFE)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDBEAFE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDBEAFE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _royalBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _royalBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _royalBlue,
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDBEAFE),
          elevation: 8,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFDBEAFE),
          selectedIconTheme: const IconThemeData(color: _royalBlue),
          unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
          selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w700,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
    if (supabaseInitializationError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase gagal diinisialisasi:\n$supabaseInitializationError',
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white,
              foregroundColor: _royalBlue,
              child: const Icon(Icons.school_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: $studentNim  •  Pendidikan Teknik Informatika',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const StudentHeader(),
              const SizedBox(height: 24),
              Text(
                'Selamat datang',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ringkasan aktivitas belajarmu ada di sini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Ringkasan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    layoutName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: columnCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width < 600
                    ? 2.6
                    : width < 840
                    ? 2.4
                    : 3.2,
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
              const SizedBox(height: 24),
              Text(
                'Materi yang dipelajari',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(Icons.api_rounded, size: 17),
                    label: Text('REST API'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: Icon(Icons.sync_alt_rounded, size: 17),
                    label: Text('HTTP CRUD'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: Icon(Icons.cloud_outlined, size: 17),
                    label: Text('Supabase'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: Icon(Icons.storage_rounded, size: 17),
                    label: Text('PostgreSQL'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: Icon(Icons.layers_outlined, size: 17),
                    label: Text('Repository Pattern'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                  Chip(
                    avatar: Icon(Icons.devices_rounded, size: 17),
                    label: Text('Responsive UI'),
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _royalBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Course Data Manager membantu mengelola materi dan progres perkuliahan.',
                      ),
                    ),
                  ],
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: _royalBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w800,
                    ),
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
  bool isRunningRlsTest = false;

  String _displayName(UserProfile? profile) {
    final name = profile?.name.trim() ?? '';
    return name.isNotEmpty ? name : studentName;
  }

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

  Future<void> editProfileName(UserProfile profile) async {
    final controller = TextEditingController(text: _displayName(profile));
    final dialogFormKey = GlobalKey<FormState>();
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah nama profil'),
        content: Form(
          key: dialogFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama tidak boleh kosong'
                : null,
            onFieldSubmitted: (value) {
              if (dialogFormKey.currentState!.validate()) {
                Navigator.pop(dialogContext, value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (dialogFormKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.trim().isEmpty || !mounted) return;
    try {
      await context.read<ProfileProvider>().updateName(newName);
      if (mounted) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Nama profil berhasil diperbarui.')),
        );
      }
    } on Object catch (error) {
      debugPrint('[ERROR] Gagal memperbarui nama profil: $error');
      if (mounted) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Nama profil gagal diperbarui: $error')),
        );
      }
    }
  }

  Future<void> confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Sesi akun ini akan diakhiri dan kamu perlu login kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AuthService.instance.logout();
    } on Object catch (error) {
      debugPrint('[ERROR] Logout gagal: $error');
      if (mounted) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Logout gagal: $error')),
        );
      }
    }
  }

  Future<void> runRlsSecurityTest() async {
    if (isRunningRlsTest) return;
    setState(() => isRunningRlsTest = true);
    try {
      await RlsSecurityTest.runAsStudent();
    } on Object catch (error) {
      debugPrint('[ERROR] Uji RLS gagal dijalankan: $error');
      if (mounted) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Uji RLS gagal dijalankan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => isRunningRlsTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileProvider>();
    final profile = profileState.profile;
    final role = profileState.role;
    final displayName = _displayName(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (SupabaseConfig.isConfigured)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded),
                onPressed: confirmLogout,
              ),
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
                    _ProfileHeroCard(
                      displayName: displayName,
                      role: role,
                      onEdit: profile == null || profileState.isUpdatingName
                          ? null
                          : () => editProfileName(profile),
                      isSaving: profileState.isUpdatingName,
                    ),
                    if (SupabaseConfig.isConfigured) ...[
                      const SizedBox(height: 16),
                      if (profileState.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (profile != null)
                        _AccountDetailsCard(
                          displayName: displayName,
                          email: profile.email.isEmpty
                              ? 'Email tidak tersedia'
                              : profile.email,
                          role: role,
                        )
                      else if (profileState.error != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Profil gagal dimuat: ${profileState.error}',
                            ),
                          ),
                        ),
                      if (kDebugMode && profile?.role == 'student') ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isRunningRlsTest
                              ? null
                              : runRlsSecurityTest,
                          icon: isRunningRlsTest
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.security_outlined),
                          label: Text(
                            isRunningRlsTest
                                ? 'Menguji RLS...'
                                : 'Uji keamanan RLS (debug)',
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 18),
                    Card(
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  foregroundColor: _royalBlue,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kirim Feedback',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: const Color(0xFF1E3A8A),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        'Bagikan saran untuk pengembangan aplikasi.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nama',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: nimController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'NIM',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'NIM wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: feedbackController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Feedback',
                                hintText: 'Tulis minimal 5 karakter',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 48),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: _royalBlue,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 5) {
                                  return 'Feedback minimal 5 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSubmitting ? null : submitForm,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _royalBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(
                                  isSubmitting
                                      ? 'Mengirim...'
                                      : 'Kirim Feedback',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.displayName,
    required this.role,
    required this.onEdit,
    required this.isSaving,
  });

  final String displayName;
  final String role;
  final VoidCallback? onEdit;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1E3A8A),
                child: Icon(Icons.person_rounded, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'NIM: 2415051026 • Pendidikan Teknik Informatika',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _RoleBadge(isAdmin: isAdmin),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit nama profil',
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.edit_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.verified_user_rounded : Icons.school_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            'ROLE: ${isAdmin ? 'ADMIN' : 'STUDENT'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String displayName;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDBEAFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.manage_accounts_outlined,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AccountInfoRow(
              icon: Icons.badge_rounded,
              label: 'Nama Lengkap',
              value: displayName,
              valueWeight: FontWeight.w700,
            ),
            _AccountInfoRow(
              icon: Icons.email_rounded,
              label: 'Email Terdaftar',
              value: email,
              valueWeight: FontWeight.w600,
            ),
            _AccountInfoRow(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Hak Akses (Role)',
              value: isAdmin
                  ? 'Admin (Kelola Semua Course)'
                  : 'Student (Lihat & Favorit Course)',
              valueWeight: FontWeight.w700,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueWeight,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final FontWeight valueWeight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 9, bottom: isLast ? 8 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: valueWeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
